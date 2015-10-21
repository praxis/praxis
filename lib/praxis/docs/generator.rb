module Praxis
  module Docs

    class Generator
      API_DOCS_DIRNAME = 'docs/api'

      attr_reader :resources_by_version, :types_by_id, :infos_by_version
      attr_reader :doc_root_dir

      EXCLUDED_TYPES_FROM_OUTPUT = Set.new([
        Attributor::Boolean,
        Attributor::CSV,
        Attributor::DateTime,
        Attributor::Float,
        Attributor::Hash,
        Attributor::Ids,
        Attributor::Integer,
        Attributor::Object,
        Attributor::String,
        Attributor::Symbol
      ]).freeze


      def initialize(root)
        require 'yaml'
        @resources_by_version =  Hash.new do |h,k|
          h[k] = Set.new
        end
        initialize_directories(root)

        Attributor::AttributeResolver.current = Attributor::AttributeResolver.new
        collect_infos
        collect_resources
        collect_types
      end

      def save!
        write_index_file
        resources_by_version.keys.each do |version|
          write_version_file(version)
        end
      end

      private

      def initialize_directories(root)
        @doc_root_dir = File.join(root, API_DOCS_DIRNAME)

        # remove previous data (and reset the directory)
        FileUtils.rm_rf @doc_root_dir if File.exists?(@doc_root_dir)
        FileUtils.mkdir_p @doc_root_dir unless File.exists? @doc_root_dir
      end

      def collect_resources
        # load all resource definitions registered with Praxis
        Praxis::Application.instance.resource_definitions.map do |resource|
          # skip resources with doc_visibility of :none
          next if resource.metadata[:doc_visibility] == :none
          version = resource.version
          # TODO: it seems that we shouldn't hardcode n/a in Praxis
          #  version = "unversioned" if version == "n/a"
          @resources_by_version[version] << resource
        end
      end

      def collect_types
        @types_by_id = ObjectSpace.each_object( Class ).select do |obj|
          obj < Attributor::Type
        end.index_by(&:id)
      end

      def collect_infos
        # All infos. Including keys for `:global`, "n/a", and any string version
        @infos_by_version = ApiDefinition.instance.describe
      end


      # Recursively inspect the structure in data and collect any
      # newly discovered types into the `reachable_types` in/out parameter
      def collect_reachable_types( data, reachable_types )
        case data
        when Array
          data.collect{|item| collect_reachable_types( item , reachable_types) }
        when Hash
          if data.key?(:type) && data[:type].kind_of?(Hash) && ( [:id,:name,:family] - data[:type].keys ).empty?
            type_id = data[:type][:id]
            unless type_id.nil?
              unless types_by_id[type_id]
                raise "Error! We have detected a reference to a 'Type' which is not derived from Attributor::Type" +
                      " Document generation cannot proceed."
              end
              reachable_types << types_by_id[type_id]
            end
          end
          data.values.map{|item| collect_reachable_types( item , reachable_types)}
        end
        reachable_types
      end

      def write_index_file
        # Gather the versions
        versions = infos_by_version.keys.reject{|v| v == :global || v == :traits }.map do |version|
          version == "n/a" ? "unversioned" : version
        end
        data = {
          info: infos_by_version[:global][:info],
          versions: versions
          # Note, I don't think we need to report the global traits (but rather the ones in the version)
        }
        filename = File.join(doc_root_dir, "index-new.json")
        puts "Generating Index file: #{filename}"
        File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(data))}
      end

      def write_version_file( version )
        version_info = infos_by_version[version]
        # Hack, let's "inherit/copy" all traits of a version from the global definition
        # Eventually traits should be defined for a version (and inheritable from global) so we'll emulate that here
        version_info[:traits] = infos_by_version[:traits]
        dumped_resources = dump_resources( resources_by_version[version] )
        found_media_types =  resources_by_version[version].collect {|r| r.media_type.describe }

        collected_types = Set.new
        collect_reachable_types( dumped_resources, collected_types );
        collect_reachable_types( found_media_types , collected_types );

        dumped_schemas = dump_schemas( collected_types )

        full_data = {
          info: version_info[:info],
          resources: dumped_resources,
          schemas: dumped_schemas,
          traits: version_info[:traits] || []
        }
        # Write the file
        version_file = ( version == "n/a" ? "unversioned" : version )
        filename = File.join(doc_root_dir, version_file)

        puts "Generating API file: #{filename} (in json and yaml)"
        File.open(filename+".json", 'w') {|f| f.write(JSON.pretty_generate(full_data))}
        File.open(filename+".yml", 'w') {|f| f.write(YAML.dump(full_data))}
      end


      def dump_resources( resources )
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

            action_description = resource_description[:actions].find {|a| a[:name] == action_name }
          end

          hash[r.id] = resource_description
        end
      end


      def dump_schemas(types)
        reportable_types = types - EXCLUDED_TYPES_FROM_OUTPUT
        reportable_types.each_with_object({}) do |type, array|
          context = [type.id]
          example_data = type.example(context)
          type_output = type.describe(false, example: example_data)
          unless type_output[:display_name]
            # For non MediaTypes or pure types or anonymous types fallback to their name, and worst case to their id
            type_output[:display_name] = type_output[:name] || type_output[:id]
          end
          if type_output[:views]
            type_output[:views].delete(:master)
            type_output[:views].each do |view_name, view_info|
              view_info[:example] = example_data.render(view: view_name)
            end
          end
          type_output[:example] = if example_data.respond_to? :render
            example_data.render(view: :master)
          else
            type.dump(example_data)
          end
          array[type.id] = type_output
        end
      end


      def dump_example_for(context_name, object)
        example = object.example(Array(context_name))
        if object.is_a? Praxis::Blueprint
          example.render(view: :master)
        elsif object.is_a? Attributor::Attribute
          object.dump(example)
        else
          raise "Do not know how to dump this object (it is not a Blueprint or an Attribute): #{object}"
        end
      end

    end
  end
end
