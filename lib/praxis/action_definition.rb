# A RESTful action allows you to define the following:
# - a payload structure
# - a params structure
# - the response MIME type
# - the return code/s ?
#
# Plugins may be used to extend this Config DSL.
#
module Praxis
  class ActionDefinition

    attr_reader :name
    attr_reader :resource_definition
    attr_reader :routes
    attr_reader :primary_route
    attr_reader :named_routes


    def initialize(name, resource_definition, **opts, &block)
      @name = name
      @resource_definition = resource_definition
      @responses = Hash.new
      @response_groups = Set.new
      @compiled_responses = nil

      if (media_type = resource_definition.media_type)
        if media_type.kind_of?(Class) && media_type < Praxis::MediaType
          @reference_media_type = media_type
        end
      end

      if resource_definition.params
        saved_type, saved_opts, saved_block = resource_definition.params
        params(saved_type, saved_opts, &saved_block)
      end

      if resource_definition.payload
        saved_type, saved_opts, saved_block = resource_definition.payload
        payload(saved_type, saved_opts, &saved_block)
      end

      if resource_definition.headers
        saved_opts, saved_block = resource_definition.headers
        headers(saved_opts, &saved_block)
      end

      self.instance_eval(&block) if block_given?
    end

    def update_attribute(attribute, options, block)
      attribute.options.merge!(options)
      attribute.type.attributes(options, &block)
    end

    def response(name, **args )
      @responses[name] = args
    end

    def response_groups(*response_groups)
      @response_groups.merge(response_groups)
    end

    def allowed_responses
      # Need to collect the names only
      groups = @response_groups + resource_definition.response_groups      
      names = @responses.keys + resource_definition.responses.keys
      groups + names 
    end

    def responses
      compiled_responses
    end
    
    def compiled_responses
      #TODO: we should really do a finalize...to make sure that late additions don't happen..      
      return @compiled_responses ||= begin
        # Make sure to incude reponses in the :default group too
        templates = ApiDefinition.instance.responses(names: @responses.keys+resource_definition.responses.keys, 
                                                     groups: @response_groups.to_a + [:default] + resource_definition.response_groups.to_a)
        
        # For each configured response, create an instance of it, passing the right arguments and 
        # We could reuse any instances that have no extra arguments (perhaps from a basic ResponseDefinition stored with the template?)
        templates.each_with_object({}) do |template, hash|
          args = @responses[template.name] || {}
          hash[template.name] = Praxis::ResponseDefinition.new(template.name, group: template.group, **args, &template.block)       
        end
      end

    end
    
    def create_attribute(type=Attributor::Struct, **opts, &block)
      unless opts[:reference]
        opts[:reference] = @reference_media_type if @reference_media_type && block
      end

      return Attributor::Attribute.new(type, opts, &block)
    end

    def use(trait_name)
      raise "Trait #{trait_name} not found in the system" unless ApiDefinition.instance.traits.has_key? trait_name
      self.instance_eval(&ApiDefinition.instance.traits[trait_name])
    end

    def params(type=Attributor::Struct, **opts, &block)
      return @params if !block && type == Attributor::Struct

      if @params
        unless type == Attributor::Struct && @params.type < Attributor::Struct
          raise 'type mismatch'
        end
        update_attribute(@params, opts, block)
      else
        @params = create_attribute(type, **opts, &block)
      end
    end

    def payload(type=Attributor::Struct, **opts, &block)
      return @payload if !block && type == Attributor::Struct

      if @payload
        unless type == Attributor::Struct && @payload.type < Attributor::Struct
          raise 'type mismatch'
        end
        update_attribute(@payload, opts, block)
      else
        @payload = create_attribute(type, **opts, &block)
      end
    end

    def headers(**opts, &block)
      return @headers unless block

      if @headers
        update_attribute(@headers, opts, block)
      else
        @headers = create_attribute(dsl_compiler: HeadersDSLCompiler, **opts, &block)
      end
    end

    def routing(&block)
      routing_config = Skeletor::RestfulRoutingConfig.new(name, resource_definition, &block)

      @routes = routing_config.routes
      @primary_route = routing_config.routes.first
      @named_routes = routing_config.routes.each_with_object({}) do |route, hash|
        next if route.name.nil?
        hash[route.name] = route
      end
    end

    def description(text = nil)
      @description = text if text
      @description
    end



    def describe
      {}.tap do |hash|
        hash[:description] = description
        hash[:name] = name
        # FIXME: change to :routes along with api browser
        hash[:urls] = routes.collect(&:describe)
        hash[:headers] = headers.describe if headers
        hash[:params] = params.describe if params
        hash[:payload] = payload.describe if payload
        hash[:responses] = allowed_responses.inject({}) do |memo, response|
          memo[response.name] = response.describe
          memo
        end
      end
    end

  end
end
