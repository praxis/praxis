# frozen_string_literal: true

require_relative 'open_api/info_object'
require_relative 'open_api/server_object'
require_relative 'open_api/paths_object'
require_relative 'open_api/tag_object'

module Praxis
  module Docs
    class OpenApiGenerator
      require 'active_support/core_ext/enumerable' # For index_by
      include Singleton

      API_DOCS_DIRNAME = 'docs/openapi'
      EXCLUDED_TYPES_FROM_OUTPUT = Set.new([
                                             Attributor::Boolean,
                                             Attributor::CSV,
                                             Attributor::DateTime,
                                             Attributor::Date,
                                             Attributor::Float,
                                             Attributor::Hash,
                                             Attributor::Ids,
                                             Attributor::Integer,
                                             Attributor::Object,
                                             Attributor::String,
                                             Attributor::Symbol,
                                             Attributor::URI
                                           ]).freeze

      attr_reader :resources_by_version, :infos_by_version, :doc_root_dir

      # substitutes ":params_like_so" for {params_like_so}
      def self.templatize_url(string)
        Mustermann.new(string).to_templates.first
      end

      def save!
        raise 'You need to configure the root directory before saving (configure_root(<dir>))' unless @root

        initialize_directories
        # Restrict the versions listed in the index file to the ones for which we have at least 1 resource
        write_index_file(for_versions: resources_by_version.keys)
        resources_by_version.each_key do |version|
          @seen_components_for_current_version = Set.new
          write_version_file(version)
        end
      end

      def initialize
        require 'yaml'

        @resources_by_version = Hash.new do |h, k|
          h[k] = Set.new
        end
        # List of types that we have seen/marked as necessary to list in the components/schemas section
        # These should contain any mediatype define in the versioned controllers plus any type
        # for which we've explicitly rendered a $ref schema
        @seen_components_for_current_version = Set.new
        @infos = ApiDefinition.instance.infos
        collect_resources
      end

      def configure_root(root)
        @root = root
      end

      def register_seen_component(type)
        @seen_components_for_current_version.add(type)
      end

      private

      def collect_resources
        # load all resource definitions registered with Praxis
        Praxis::Application.instance.endpoint_definitions.map do |resource|
          # skip resources with doc_visibility of :none
          next if resource.metadata[:doc_visibility] == :none

          version = resource.version
          # TODO: it seems that we shouldn't hardcode n/a in Praxis
          #  version = "unversioned" if version == "n/a"
          @resources_by_version[version] << resource
        end
      end

      def write_index_file(for_versions:)
        # TODO. create a simple html file that can link to the individual versions available
      end

      # TODO: Change this function name to scan_default_mediatypes...
      def collect_default_mediatypes(endpoints)
        # We'll start by processing the rendered mediatypes
        Set.new(endpoints.select do |endpoint|
          endpoint.media_type && !endpoint.media_type.is_a?(Praxis::SimpleMediaType)
        end.collect(&:media_type))
      end

      def write_version_file(version)
        # version_info = infos_by_version[version]
        # # Hack, let's "inherit/copy" all traits of a version from the global definition
        # # Eventually traits should be defined for a version (and inheritable from global) so we'll emulate that here
        # version_info[:traits] = infos_by_version[:traits]

        # We'll for sure include any of the default mediatypes in the endpoints for this version
        @seen_components_for_current_version.merge(collect_default_mediatypes(resources_by_version[version]))
        # Here we have:
        # processed types: which includes default mediatypes for the processed endpoints
        # processed resources for this version: resources_by_version[version]

        info_object = OpenApi::InfoObject.new(version: version, api_definition_info: @infos[version])
        # We only support a server in Praxis ... so we'll use the base path
        server_params = {}
        if(server_info = @infos[version].server)
          server_params[:url] = server_info[:url]
          server_params[:variables] = server_info[:variables] if server_info[:variables]
        else
          server_params[:url] = @infos[version].base_path
        end
        server_params[:description] = server_info[:description] if server_info[:description]
        server_object = OpenApi::ServerObject.new(**server_params)

        paths_object = OpenApi::PathsObject.new(resources: resources_by_version[version])

        full_data = {
          openapi: '3.0.2',
          info: info_object.dump,
          servers: [server_object.dump],
          paths: paths_object.dump,
          security: [] # NOTE: No security definitions in Praxis. Leave it empty, to not anger linters
          # responses: {}, #TODO!! what do we get here? the templates?...need to transform to "Responses Definitions Object"
          # securityDefinitions: {}, # NOTE: No security definitions in Praxis
        }

        # Create the top level tags by:
        # 1- First adding all the resource display names (and descriptions)
        tags_for_resources = resources_by_version[version].collect do |resource|
          OpenApi::TagObject.new(name: resource.display_name, description: resource.description).dump
        end
        full_data[:tags] = tags_for_resources
        # 2- Then adding all of the top level traits but marking them special with the x-traitTag (of Redoc)
        tags_for_traits = ApiDefinition.instance.traits.collect do |name, info|
          OpenApi::TagObject.new(name: name, description: info.description).dump.merge('x-traitTag': true)
        end
        full_data[:tags] = full_data[:tags] + tags_for_traits unless tags_for_traits.empty?

        # Include only MTs and Blueprints (i.e., no simple types...)
        component_schemas = add_component_schemas(@seen_components_for_current_version.clone, {})

        # 3- Then adding all of the top level Mediatypes...so we can present them at the bottom, otherwise they don't show
        tags_for_mts = component_schemas.map do |(name, _info)|
          special_redoc_anchor = "<SchemaDefinition schemaRef=\"#/components/schemas/#{name}\" showReadOnly={true} showWriteOnly={true} />"
          guessed_display = name.split('-').last # TODO!!!the informational hash does not seem to come with the "description" value set...hmm
          OpenApi::TagObject.new(name: name, description: special_redoc_anchor).dump.merge('x-displayName': guessed_display)
        end
        full_data[:tags] = full_data[:tags] + tags_for_mts unless tags_for_mts.empty?

        # Include all the reusable schemas in the components hash
        full_data[:components] = {
          schemas: component_schemas
        }

        # Common params/headers for versioning (actions will link to them when appropriate, by name)
        if (version_with = @infos[version].version_with)
          common_params = {}
          if version_with.include?(:header)
            common_params['ApiVersionHeader'] = { 
              in: 'header',
              name: 'X-Api-Version',
              schema: { type: 'string', enum: [version]},
              required: version_with.size == 1
            }
          end
          if version_with.include?(:params)
            common_params['ApiVersionParam'] = { 
              in: :query,
              name: 'api_version',
              schema: { type: 'string', enum: [version]},
              required: version_with.size == 1
            }
          end
          full_data[:components][:parameters] = common_params
        end

        # REDOC specific grouping of sidebar
        resource_tags = { name: 'Resources', tags: tags_for_resources.map { |t| t[:name] } }
        schema_tags = { name: 'Models', tags: tags_for_mts.map { |t| t[:name] } }
        full_data['x-tagGroups'] = [resource_tags, schema_tags]

        # if parameter_object = convert_to_parameter_object( version_info[:info][:base_params] )
        #   full_data[:parameters] = parameter_object
        # end
        # puts JSON.pretty_generate( full_data )
        # Write the file
        version_file = (version == 'n/a' ? 'unversioned' : version)
        filename = File.join(doc_root_dir, version_file, 'openapi')

        puts "Generating Open API file : #{filename} (json and yml) "
        json_data = JSON.pretty_generate(full_data)
        File.open("#{filename}.json", 'w') { |f| f.write(json_data) }
        converted_full_data = JSON.parse(json_data) # So symbols disappear
        File.open("#{filename}.yml", 'w') { |f| f.write(YAML.dump(converted_full_data)) }

        html = <<~HTML
          <!doctype html>
          <html lang="en">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
              <title>Elements in HTML</title>
          #{'  '}
              <script src="https://unpkg.com/@stoplight/elements/web-components.min.js"></script>
              <link rel="stylesheet" href="https://unpkg.com/@stoplight/elements/styles.min.css">
            </head>
            <body>

              <elements-api
                apiDescriptionUrl="http://localhost:9090/#{version_file}/openapi.json"
                router="hash"
              />

            </body>
          </html>
        HTML
        html_file = File.join(doc_root_dir, version_file, 'index.html')
        File.write(html_file, html)
      end

      def initialize_directories
        @doc_root_dir = File.join(@root, API_DOCS_DIRNAME)

        # remove previous data (and reset the directory)
        FileUtils.rm_rf @doc_root_dir if File.exist?(@doc_root_dir)
        FileUtils.mkdir_p @doc_root_dir unless File.exist? @doc_root_dir
        resources_by_version.each_key do |version|
          FileUtils.mkdir_p "#{@doc_root_dir}/#{version}"
        end
        FileUtils.mkdir_p "#{@doc_root_dir}/unversioned" if resources_by_version.keys.include?('n/a')
      end

      def normalize_media_types(mtis)
        mtis.collect do |mti|
          MediaTypeIdentifier.load(mti).to_s
        end
      end

      def add_component_schemas(types_to_add, components_hash)
        initial = @seen_components_for_current_version.dup
        types_to_add.each_with_object(components_hash) do |(type), accum|
          # For components, we want the first level to be fully dumped (only references below that)
          accum[type.id] = OpenApi::SchemaObject.new(info: type).dump_schema(allow_ref: false, shallow: false)
        end
        newfound = @seen_components_for_current_version - initial
        # Process the new types if they have discovered
        add_component_schemas(newfound, components_hash) unless newfound.empty?
        components_hash
      end

      def convert_to_parameter_object(params)
        # TODO!! actually convert each of them
        puts 'TODO! convert to parameter object'
        params
      end

      def convert_traits_to_tags(traits)
        traits.collect do |name, info|
          { name: name, description: info[:description] }
        end
      end

      def dump_responses_object(responses)
        responses.each_with_object({}) do |(_name, info), hash|
          data = { description: info[:description] || '' }
          if (payload = info[:payload])
            body_type = payload[:id]
            raise "WAIT! response payload doesn't have an existing id for the schema!!! (do an if, and describe it if so)" unless body_type

            data[:schema] = { '$ref' => "#/definitions/#{body_type}" }
          end

          #          data[:schema] = ???TODO!!
          if (headers_object = dump_response_headers_object(info[:headers]))
            data[:headers] = headers_object
          end
          if info[:payload] && (examples_object = dump_response_examples_object(info[:payload][:examples]))
            data[:examples] = examples_object
          end
          hash[info[:status]] = data
        end
      end
      # def dump_response_headers_object( headers )
      #   puts "WARNING!! Finish this. It seems that headers for responses are never set in the hash??"
      #   unless headers.empty?
      #     binding.pry
      #     puts headers
      #   end
      # end

      def dump_response_examples_object(examples)
        examples.each_with_object({}) do |(_name, info), hash|
          hash[info[:content_type]] = info[:body]
        end
      end

      def dump_resources(resources)
        resources.each_with_object({}) do |r, hash|
          # Do not report undocumentable resources
          next if r.metadata[:doc_visibility] == :none

          context = [r.id]
          resource_description = r.describe(context: context)

          # strip actions with doc_visibility of :none
          resource_description[:actions].reject! { |a| a[:metadata][:doc_visibility] == :none }

          # Go through the params/payload of each action and augment them by
          # adding a generated example (then stick it into the description hash)
          r.actions.each do |action_name, action|
            # skip actions with doc_visibility of :none
            next if action.metadata[:doc_visibility] == :none

            resource_description[:actions].find { |a| a[:name] == action_name }
          end

          hash[r.id] = resource_description
        end
      end
    end
  end
end
