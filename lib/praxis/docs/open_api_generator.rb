# frozen_string_literal: true
require_relative 'open_api/info_object'
require_relative 'open_api/server_object'
require_relative 'open_api/paths_object'
require_relative 'open_api/tag_object'

module Praxis
  module Docs
    class OpenApiGenerator
      require 'active_support/core_ext/enumerable' # For index_by

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

      attr_reader :resources_by_version, :types_by_id, :infos_by_version, :doc_root_dir

      # substitutes ":params_like_so" for {params_like_so}
      def self.templatize_url(string)
        Mustermann.new(string).to_templates.first
      end

      def save!
        initialize_directories
        # Restrict the versions listed in the index file to the ones for which we have at least 1 resource
        write_index_file(for_versions: resources_by_version.keys)
        resources_by_version.keys.each do |version|
          write_version_file(version)
        end
      end

      def initialize(root)
        require 'yaml'
        @root = root
        @resources_by_version = Hash.new do |h, k|
          h[k] = Set.new
        end

        @infos = ApiDefinition.instance.infos
        collect_resources
        collect_types
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

      def collect_types
        @types_by_id = ObjectSpace.each_object(Class).select do |obj|
          obj < Attributor::Type
        end.index_by(&:id)
      end

      def write_index_file(for_versions:)
        # TODO. create a simple html file that can link to the individual versions available
      end

      def scan_types_for_version(version, dumped_resources)
        found_media_types = resources_by_version[version].select { |r| r.media_type }.collect { |r| r.media_type.describe }

        # We'll start by processing the rendered mediatypes
        processed_types = Set.new(resources_by_version[version].select do |r|
          r.media_type && !r.media_type.is_a?(Praxis::SimpleMediaType)
        end.collect(&:media_type))

        newfound = Set.new
        found_media_types.each do |mt|
          newfound += scan_dump_for_types({ type: mt }, processed_types)
        end
        # Then will process the rendered resources (noting)
        newfound += scan_dump_for_types(dumped_resources, Set.new)

        # At this point we've done a scan of the dumped resources and mediatypes.
        # In that scan we've discovered a bunch of types, however, many of those might have appeared in the JSON
        # rendered in just shallow mode, so it is not guaranteed that we've seen all the available types.
        # For that we'll do a (non-shallow) dump of all the types we found, and scan them until the scans do not
        # yield types we haven't seen before
        until newfound.empty?
          dumped = newfound.collect(&:describe)
          processed_types += newfound
          newfound = scan_dump_for_types(dumped, processed_types)
        end
        processed_types
      end

      def scan_dump_for_types(data, processed_types)
        newfound_types = Set.new
        case data
        when Array
          data.collect { |item| newfound_types += scan_dump_for_types(item, processed_types) }
        when Hash
          if data.key?(:type) && data[:type].is_a?(Hash) && (%i[id name family] - data[:type].keys).empty?
            type_id = data[:type][:id]
            unless type_id.nil? || type_id == Praxis::SimpleMediaType.id # SimpleTypes shouldn't be collected
              unless types_by_id[type_id]
                raise "Error! We have detected a reference to a 'Type' with id='#{type_id}' which is not derived from Attributor::Type" +
                      ' Document generation cannot proceed.'
              end
              newfound_types << types_by_id[type_id] unless processed_types.include? types_by_id[type_id]
            end
          end
          data.values.map { |item| newfound_types += scan_dump_for_types(item, processed_types) }
        end
        newfound_types
      end

      def write_version_file(version)
        # version_info = infos_by_version[version]
        # # Hack, let's "inherit/copy" all traits of a version from the global definition
        # # Eventually traits should be defined for a version (and inheritable from global) so we'll emulate that here
        # version_info[:traits] = infos_by_version[:traits]
        dumped_resources = dump_resources(resources_by_version[version])
        processed_types = scan_types_for_version(version, dumped_resources)

        # Here we have:
        # processed types: which includes mediatypes and normal types...real classes
        # processed resources for this version: resources_by_version[version]

        info_object = OpenApi::InfoObject.new(version: version, api_definition_info: @infos[version])
        # We only support a server in Praxis ... so we'll use the base path
        server_object = OpenApi::ServerObject.new(url: @infos[version].base_path)

        paths_object = OpenApi::PathsObject.new(resources: resources_by_version[version])

        full_data = {
          openapi: '3.0.2',
          info: info_object.dump,
          servers: [server_object.dump],
          paths: paths_object.dump
          # responses: {}, #TODO!! what do we get here? the templates?...need to transform to "Responses Definitions Object"
          # securityDefinitions: {}, # NOTE: No security definitions in Praxis
          # security: [], # NOTE: No security definitions in Praxis
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

        # Include only MTs (i.e., not custom types or simple types...)
        component_schemas = reusable_schema_objects(processed_types.select { |t| t < Praxis::MediaType })

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
        File.open(filename + '.json', 'w') { |f| f.write(json_data) }
        converted_full_data = JSON.parse(json_data) # So symbols disappear
        File.open(filename + '.yml', 'w') { |f| f.write(YAML.dump(converted_full_data)) }

        html = <<-EOB
          <!DOCTYPE html>
          <html>
            <head>
              <title>ReDoc</title>
              <!-- needed for adaptive design -->
              <meta charset="utf-8"/>
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <link href="https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700" rel="stylesheet">

              <!--
              ReDoc doesn't change outer page styles
              -->
              <style>
                body {
                  margin: 0;
                  padding: 0;
                }
              </style>
            </head>
            <body>
              <redoc spec-url='http://localhost:9090/#{version_file}/openapi.json'></redoc>
              <script src="https://cdn.jsdelivr.net/npm/redoc@next/bundles/redoc.standalone.js"> </script>
            </body>
          </html>
        EOB
        html_file = File.join(doc_root_dir, version_file, 'index.html')
        File.write(html_file, html)
      end

      def initialize_directories
        @doc_root_dir = File.join(@root, API_DOCS_DIRNAME)

        # remove previous data (and reset the directory)
        FileUtils.rm_rf @doc_root_dir if File.exist?(@doc_root_dir)
        FileUtils.mkdir_p @doc_root_dir unless File.exist? @doc_root_dir
        resources_by_version.keys.each do |version|
          FileUtils.mkdir_p @doc_root_dir + '/' + version
        end
        FileUtils.mkdir_p @doc_root_dir + '/unversioned' if resources_by_version.keys.include?('n/a')
      end

      def normalize_media_types(mtis)
        mtis.collect do |mti|
          MediaTypeIdentifier.load(mti).to_s
        end
      end

      def reusable_schema_objects(types)
        types.each_with_object({}) do |(type), accum|
          the_type = \
            if type.respond_to? :as_json_schema
              type
            else # If it is a blueprint ... for now, it'd be through the attribute
              type.attribute
            end
          accum[type.id] = the_type.as_json_schema(shallow: false)
        end
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
          if payload = info[:payload]
            body_type = payload[:id]
            raise "WAIT! response payload doesn't have an existing id for the schema!!! (do an if, and describe it if so)" unless body_type

            data[:schema] = { '$ref' => "#/definitions/#{body_type}" }
          end

          #          data[:schema] = ???TODO!!
          if headers_object = dump_response_headers_object(info[:headers])
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

            action_description = resource_description[:actions].find { |a| a[:name] == action_name }
          end

          hash[r.id] = resource_description
        end
      end
    end
  end
end
