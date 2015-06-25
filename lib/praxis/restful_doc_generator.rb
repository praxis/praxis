module Praxis
  class RestfulDocGenerator

    class << self
      attr_reader :inspected_types
    end

    @inspected_types = Set.new
    API_DOCS_DIRNAME = 'docs/api'

    EXCLUDED_TYPES_FROM_TOP_LEVEL = Set.new([
      Attributor::Boolean,
      Attributor::CSV,
      Attributor::DateTime,
      Attributor::Float,
      Attributor::Hash,
      Attributor::Ids,
      Attributor::Integer,
      Attributor::Object,
      Attributor::String
    ]).freeze

    def self.inspect_attributes(the_type)

      reachable = Set.new
      return reachable if the_type.nil? || the_type.is_a?(Praxis::SimpleMediaType)

      # If an attribute comes in, get its type
      the_type = the_type.type if the_type.is_a? Attributor::Attribute

      # Collection types are special since they wrap a member type, so let's reach in and grab it
      the_type = the_type.member_attribute.type if the_type < Attributor::Collection

      if @inspected_types.include? the_type
        # We're done if we've already inspected it
        return reachable
      else
        # Mark it as inspected (before recursing)
        @inspected_types << the_type  unless the_type.name == nil # Don't bother with anon structs
      end
      #puts "Inspecting type: #{the_type.name}"    if the_type.name != nil

      reachable << the_type  unless the_type.name == nil # Don't bother with anon structs
      if the_type.respond_to? :attributes
        the_type.attributes.each do |name, attr|
          attr_type = attr.type
          #puts "Inspecting attr: #{name} (class: #{attr_type.name}) #{attr_type.inspect}"
          reachable += self.inspect_attributes(attr_type)
        end
      end
      reachable
    end

    class Resource

      attr_accessor :media_type, :reachable_types, :version, :controller_config

      def initialize( definition )
        @controller_config = definition
        if controller_config.version == 'n/a'
          @version = 'unversioned'
        else
          @version = controller_config.version
        end
        @media_type = controller_config.media_type
        @reachable_types = Set.new

        # Collect reachable types from the media_type if any (plus itself)
        if @media_type && ! @media_type.is_a?(Praxis::SimpleMediaType)
          add_to_reachable RestfulDocGenerator.inspect_attributes(@media_type)
          @media_type.attributes.each do |name, attr|
            add_to_reachable RestfulDocGenerator.inspect_attributes(attr)
          end
          @generated_example = @media_type.example(self.id)
        end

        # Collect reachable types from the params and payload definitions
        @controller_config.actions.each do |name, action_config|
          # skip actions with doc_visibility of :none
          next if action_config.metadata[:doc_visibility] == :none

          add_to_reachable RestfulDocGenerator.inspect_attributes(action_config.params)
          add_to_reachable RestfulDocGenerator.inspect_attributes(action_config.payload)

          action_config.responses.values.each do |response|
            add_to_reachable RestfulDocGenerator.inspect_attributes(response.media_type)
          end
        end

      end

      # TODO: I think that the "id"/"name" of a resource should be provided by the definition/controller...not derived here
      def id
        if @controller_config.controller
          @controller_config.controller.id
        else
          # If an API doesn't quite have the controller defined, let's use the name from the resource definition
          @controller_config.id
        end
      end

      def name
        if @controller_config.controller
          @controller_config.controller.name
        else
          # If an API doesn't quite have the controller defined, let's use the name from the resource definition
          @controller_config.name
        end
      end

      def friendly_name
        # FIXME: is it really about the controller? or the attached resource definition?
        segments = self.name.split("::")
        # FIXME: Crappy hack to derive a friendly name
        if ["Collection","Links"].include? segments.last
          segments[-2] + segments[-1] # concat the last 2
        else
          segments.last
        end
      end

      def add_to_reachable( found )
        return if found == nil
        @reachable_types += found
      end
    end

    def initialize(root_dir)
      @root_dir = root_dir
      @doc_root_dir = File.join(@root_dir, API_DOCS_DIRNAME)
      @resources = []

      remove_previous_doc_data
      load_resources

      # Gather all reachable types (grouped by version)
      types_for = Hash.new
      @resources.each do |r|
        types_for[r.version] ||= Set.new
        types_for[r.version] += r.reachable_types
      end

      write_resources
      write_types(types_for)
      write_index(types_for)
      write_info(types_for)
      write_templates(types_for)
    end

    def load_resources
      Praxis::Application.instance.resource_definitions.map do |resource|
        # skip resources with doc_visibility of :none
        next if resource.metadata[:doc_visibility] == :none

        @resources << Resource.new(resource)
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

    def write_resources
      @resources.each do |r|

        filename = File.join(@doc_root_dir, r.version, "resources","#{r.id}.json")
        #puts "Dumping #{r.id} to #{filename}"
        base = File.dirname(filename)
        FileUtils.mkdir_p base unless File.exists? base
        resource_description = r.controller_config.describe

        # strip actions with doc_visibility of :none
        resource_description[:actions].reject! { |a| a[:metadata][:doc_visibility] == :none }

        # Go through the params/payload of each action and generate an example for them (then stick it into the description hash)
        r.controller_config.actions.each do |action_name, action|
          # skip actions with doc_visibility of :none
          next if action.metadata[:doc_visibility] == :none

          generated_examples = {}
          if action.params
            generated_examples[:params] = dump_example_for( r.id, action.params )
          end
          if action.payload
            generated_examples[:payload] = dump_example_for( r.id, action.payload )
          end
          action_description = resource_description[:actions].find{|a| a[:name] == action_name }
          action_description[:params][:example] = generated_examples[:params] if generated_examples[:params]
          action_description[:payload][:example] = generated_examples[:payload] if generated_examples[:payload]
        end

        File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(resource_description))}
      end
    end

    def write_types( versioned_types )
      versioned_types.each do |version, types|
        dirname = File.join(@doc_root_dir, version, "types")
        FileUtils.mkdir_p dirname unless File.exists? dirname
        reportable_types = types - EXCLUDED_TYPES_FROM_TOP_LEVEL
        reportable_types.each do |type|
          filename = File.join(dirname, "#{type.id}.json")
          #puts "Dumping #{type.name} to #{filename}"
          type_output = type.describe
          example_data = type.example(type.to_s)
          if type_output[:views]
            type_output[:views].delete(:master)
            type_output[:views].each do |view_name, view_info|
              # Add and example for each view
              unless( type < Praxis::Links ) #TODO: why do we need to skip an example for links?
                view_info[:example] = example_data.render(view: view_name)
              end
            end
          end
          # Save a full type example
          # ...but not for links or link classes (there's no object container context if done alone!!)
          unless( type < Praxis::Links ) #TODO: again, why is this special?
            type_output[:example] = if example_data.respond_to? :render
              example_data.render(view: :master)
            else
              type.dump(example_data)
            end
          end

          # add an example for each attribute??
          File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(type_output))}
        end
      end
    end

    # index looks like something like this:
    #    {'1.0':
    #           {
    #           // Typical entry for controller with an associated mediatype
    #           "Post" : { media_type: "V1::MT:Post" , controller: "V1:Ctrl:Post"}
    #           // Unusual entry for controller without an associated mediatype
    #           "Admin" : { controller: "V1:Ctrl:Admin" }
    #           // Entry for mediatype that somehow is not associated with any controller...
    #           "RemoteMT" : { media_type: "V1:Ctrl:RemoteMT" }
    #           // Entry to a non-primitive type (but not a mediatype), that it is not covered by any related controller or mt
    #           "Locale" : { kind: "Module::Locale"}
    #           }
    #
    #    '2.0': {  ... }
    #    }
    def write_index( versioned_types )
      index = Hash.new
      media_types_seen_from_controllers = Set.new
      # Process the resources first

      @resources.each do |r|
        index[r.version] ||= Hash.new
        info = {controller: r.id, name: r.name}
        if r.media_type
          info[:media_type] = r.media_type.id
          media_types_seen_from_controllers << r.media_type
        end
        display_name  = r.name.split("::").last
        index[r.version][display_name] = info
      end

      versioned_types.each do |version, types|
        # Discard any mediatypes that we've already seen and processed as controller related
        reportable_types = types - media_types_seen_from_controllers - EXCLUDED_TYPES_FROM_TOP_LEVEL
        #TODO: think about these special cases, is it needed?
        reportable_types.reject!{|type| type < Praxis::Links || type < Praxis::MediaTypeCollection }

        reportable_types.each do |type|
          index[version] ||= Hash.new
          display_name = type.name.split("::").last
          if index[version].has_key? display_name
            raise "Display name already taken for version #{version}! #{display_name}"
          end
          index[version][display_name] = if type < Praxis::MediaType
            {media_type: type.id }
          else
            {kind: type.id}
          end
        end
      end
      filename = File.join(@doc_root_dir, "index.json")
      dirname = File.dirname(filename)
      FileUtils.mkdir_p dirname unless File.exists? dirname
      File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(index))}
    end

    # Writes an "index" type file inside each version, with some higher level information about the API
    def write_info( versioned_types )

      resources_by_version = Hash.new do |hash, v|
        hash[v] = Set.new
      end
      types_by_version = Hash.new do |hash, v|
        hash[v] = Set.new
      end

      @resources.each do |r|
        resources_by_version[r.version]  << { id: r.id, name: r.name, friendly_name: r.friendly_name}
      end

      versioned_types.each do |version, types|
#        # Discard any mediatypes that we've already seen and processed as controller related
        reportable_types = types - EXCLUDED_TYPES_FROM_TOP_LEVEL
#        #TODO: think about these special cases, is it needed?
#        reportable_types.reject!{|type| type < Praxis::Links || type < Praxis::MediaTypeCollection }

        reportable_types.each do |type|
          segments = type.name.split("::")
          # FIXME: Crappy hack to derive a friendly name
          friendly_name = if ["Collection","Links"].include? segments.last
            segments[-2] + segments[-1] # concat the last 2
          else
            segments.last
          end

          types_by_version[version] << { id: type.id,  name: type.name, friendly_name: friendly_name}
        end
      end
      ###############################

      diff = resources_by_version.keys - types_by_version.keys - versioned_types.keys
      raise "!!!!!!!! somehow we have a list of different versions from the types vs. resources seen" unless diff.empty?

      infos = {}
      versioned_types.each do |version, types|
        infos[version] = {info:{}}
      end
      infos.merge!(ApiDefinition.instance.describe)

      # Add resources and types list
      versioned_types.keys.each do |v|

        infos[v][:resources] = resources_by_version[v].each_with_object({}) do |element,hash|
          hash[element[:id]] = { name: element[:name], friendly_name: element[:friendly_name] }
        end
        infos[v][:schemas] = types_by_version[v].each_with_object({}) do |element,hash|
          hash[element[:id]] = {  name: element[:name], friendly_name: element[:friendly_name] }
        end
      end

      versioned_types.each do |version, types|
        dirname = File.join(@doc_root_dir, version)
        filename = File.join(dirname, "version_index.json")
        File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(infos[version]))}
      end
    end


    def write_templates(versioned_types)
      # Calculate and write top-level (non-versioned) templates
      top_templates = write_template("")
      # Calculate and write versioned templates (passing the top level ones for inheritance)
      versioned_types.keys.each do |version|
        write_template(version,top_templates)
      end
    end

    def write_template(version,top_templates=nil)
      # Collect template filenames (grouped by type: embedded vs. standalone)
      templates_dir = File.join(@root_dir,"doc_browser","templates",version)

      # Slurp in any top level (unversioned) templates if any
      # Top level templates will apply to any versioned one (and can be overwritten
      # if the version defines their own)
      templates = {embedded: {}, standalone: {} }
      if top_templates
        templates[:embedded] = top_templates[:embedded].clone
        templates[:standalone] = top_templates[:standalone].clone
      end

      dual = Dir.glob(File.join(templates_dir,"*.tmpl"))
      embedded = Dir.glob(File.join(templates_dir,"embedded","*.tmpl"))
      standalone = Dir.glob(File.join(templates_dir,"standalone","*.tmpl"))

      # TODO: Encode the contents more appropriately rather than dumping a string
      # Templates defined at the top will apply to both embedded and standalone
      # But it can be overriden if the same type exists in the more specific directory
      dual.each do |filename|
        type_key = File.basename(filename).gsub(/.tmpl$/,'')
        contents = IO.read(filename)
        templates[:embedded][type_key] = contents
        templates[:standalone][type_key] = contents
      end

      # For each embedded one, create a key in the embedded section, and encode the file contents in the value
      embedded.each do |filename|
        type_key = File.basename(filename).gsub(/.tmpl$/,'')
        templates[:embedded][type_key] = IO.read(filename)
      end
      # For each standalone one, create a key in the standalone section, and encode the file contents in the value
      standalone.each do |filename|
        type_key = File.basename(filename).gsub(/.tmpl$/,'')
        templates[:standalone][type_key] = IO.read(filename)
      end

      [:embedded,:standalone].each do |type|
        v = version.empty? ? "top level": version
        puts "Packaging #{v} #{type} templates for: #{templates[type].keys}" unless templates[type].keys.empty?
      end

      # Write the resulting hash to the final file in the docs directory
      filename = File.join(@doc_root_dir, version, "templates.json")
      dirname = File.dirname(filename)
      FileUtils.mkdir_p dirname unless File.exists? dirname
      File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(templates))}
      return templates
    end
    private

    def remove_previous_doc_data
      FileUtils.rm_rf @doc_root_dir if File.exists?(@doc_root_dir)
    end

  end
end
