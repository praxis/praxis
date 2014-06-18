module Attributor
  class DSLCompiler
    def use(name)
      raise "Trait #{name} not found in the system" unless Skeletor.traits.has_key? name
      self.instance_eval(&Skeletor.traits[name])
    end
  end
end

# Defines a simple DSL for describing a RESTful API.
module Praxis
  module Skeletor
    class RestfulSinatraApplicationConfig

      # a special media type that only returns resource count (for index actions)
      # TODO: provide a YAML config for this instead
      COUNT_MEDIA_TYPE = "application/vnd.rightscale.count"
      
      def self.inherited(klass)
        klass.configure_default_routing
      end

      def self.route_base
        # #93 - Revisit whether we can just use ActiveSupport instead
        class_name = self.name.split("::").last || ""

        class_name.gsub!(%r{Config$},'')
        # perform ActiveSupport-like "underscore" operation on the string
        class_name.gsub!(%r/(?:([A-Za-z\d])|^)((?=a)b)(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
        class_name.gsub!(%r/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
        class_name.gsub!(%r/([a-z\d])([A-Z])/,'\1_\2')
        class_name.tr!("-", "_")
        class_name.downcase!

        class_name
      end

      def self.configure_default_routing
        @mount_path = Regexp.new("^/" + self.route_base)
        @parent = nil
        @route_prefix = "/" + self.route_base
      end

      def self.route_prefix
        @route_prefix
      end


      def self.mount_path=(path)
        raise ArgumentError, "mount_path must be a Regexp" if !path.kind_of?(Regexp)
        raise ArgumentError, "invalid regexp for mount_path: #{path.inspect}" unless path.inspect[0..3] == /^\//.inspect[0..3]
        @mount_path = path
      end

      def self.mount_path
        @mount_path
      end

      def self.api_version
        settings[:api_version] || Skeletor::Request::UNVERSIONED
      end

      def self.parent
        @parent
      end

      def self.parent_id_param_name
        return nil if @parent.nil?

        # FIXME: should do Skeletor::Doc::Support.camel_case parent
        parent_singular = Skeletor::Doc::Support.singularize(parent.route_base)
        parent_singular.gsub!("/", "")
        "#{parent_singular}_id"
      end


      def self.routing(route_prefix: nil, mount_path: nil, parent: nil)
        if mount_path
          @parent = nil
          @route_prefix = ""
          self.mount_path = mount_path
          raise ArgumentError, "can not specify route_prefix if mount_path is provided" if route_prefix
          raise ArgumentError, "can not specify parent if mount_path is provided" if parent
          return
        end

        if parent && !route_prefix
          @parent = parent
          if parent < RestfulSinatraApplication #support legacy mode, where controller classes are passed, instead of Configs
            warn "Deprecated use of parent in routing: please pass a *Config class as the parent, not a controller (got: #{parent.name})! "
            @parent = parent.config_class 
          end
          @route_prefix = "#{self.parent.route_prefix}/:#{self.parent_id_param_name}/#{self.route_base}"
          self.mount_path = /^#{self.parent.route_prefix}\/[^\/]+\/#{self.route_base}/
          return
        end

        if route_prefix
          if parent
            @parent = parent
            if parent < RestfulSinatraApplication #support legacy mode, where controller classes are passed, instead of Configs
              warn "Deprecated use of parent in routing: please pass a *Config class as the parent, not a controller (got: #{parent.name})! "
              @parent = parent.config_class 
            end
            @route_prefix = "#{self.parent.route_prefix}/:#{self.parent_id_param_name}/#{route_prefix}"
          else
            @route_prefix = route_prefix
          end

          segments = @route_prefix.split('/').collect do |segment|
            segment.gsub(/(:\w+)/) { |m| '(.*?)' }
          end

          self.mount_path = %r{^#{segments.join('/')}}
          return
        end
        raise ArgumentError, "No routing parameters. You don't want this controller routed at all?"
      end


      class << self
        
        def local_settings
          @settings ||= {:strict_responses => false }
        end
        
        def set( name, value )
          local_settings[name] = value
        end
        
        def description( text = nil )
          @description = text if text
          @description
        end
        
        def settings
          inherited = if superclass < RestfulSinatraApplicationConfig
              superclass.settings
          end
            
          if inherited 
            inherited.merge(local_settings)
          else
            local_settings 
          end
        end

        def actions
          @actions ||= Hash.new
        end

        def responses
          @responses ||= Hash.new
        end
        
        # 'action' stanza of DSL
        def action(name, &block)
          opts = {}
          opts[:media_type] = media_type if media_type
          actions[name] = Skeletor::RestfulActionConfig.new(name, self, opts, &block)
        end

        def mime_type(mime_string=nil)
          return @mime_type unless mime_string
          raise "Invalid mime type specification" unless mime_string.is_a? String
          @mime_type = mime_string
        end

        # 'media_type' stanza of DSL
        def media_type( media_type_class = nil )
          return  @media_type unless media_type_class

          if @media_type || @mime_type
            raise Exception, "A media (or mime_type) type has already been defined in this config (#{self.inspect}"
          end
          unless actions.empty?
            raise Exception, "One or more actions have already been defined, please define the media_type first"
          end
          raise "Invalid media type parameter (must be a class)" unless media_type_class.is_a? Class
          raise "MediaType class for a config must derive from Skeletor::MediaType" unless media_type_class < Skeletor::MediaType
          @media_type = media_type_class
          mime_type( @media_type.mime_type ) if @media_type.mime_type
        end


        def describe
          {}.tap do |hash|
            hash[:description] = description
            hash[:media_type] = media_type.name if media_type
            hash[:mime_type] = mime_type if mime_type
            hash[:actions] = actions.values.map(&:describe)
          end
        end

        # 'response' stanza of DSL
        def response( name , &block )
           raise "Response definition for #{name} requires a block" unless block_given?
           responses[name] =  ResponseDefinition.new(name,&block)
        end
       
        # for each ancestor of app_class
        # grab its config and get common response specs
        # and accumulate those: list of response specs
        def compile_inherited_responses( app_class )
          ancestors = app_class.ancestors
          app_ancestors = ancestors.select { |k| k < RestfulSinatraApplication || k == RestfulSinatraApplication }
          reversed_app_ancestors = app_ancestors.reverse # Reverse for top-down inheritance
          compiled_responses = reversed_app_ancestors.reduce({}) do |memo, ancestor|
            memo.merge!(ancestor.config_class.responses)
          end
          compiled_responses
        end

        def finalize_responses!(app_class)
          explicit = settings[:strict_responses]
          # for each ancestor of app_class
          # grab its config and get common response specs
          # and accumulate those: list of response specs
          compiled_responses = compile_inherited_responses( app_class )

          # For each our actions:
          # inject as many specs as defined.
          actions.each do |action_name, action|
            action_responses = action.responses
            if explicit # Only bring in the specs for response names that have been explicitly defined
              action_responses.each do |action_name,action_definition|
                action_responses[action_name] = compiled_responses[action_name] if action_definition.nil?
                raise "Could not find an inheritable response spec for #{action_name} in #{app_class.name}" unless action_responses[action_name]
              end
            else # Merge (non-override) ALL responses found in the inheritance
              action_responses.merge! (compiled_responses) { | k, old_val, new_val | old_val || new_val}
            end
          end
        end
      end

      # System-wide response definitions
      response :default do
        status 200
        mime_type :controller_defined
      end

      response :validation do
        description "When parameter validation hits..."
        status 400
        mime_type "application/json"
      end

      response :internal_server_error do
        description "Internal Server Error"
        status 500
        # don't set mime_type here
      end

    end
  end
end