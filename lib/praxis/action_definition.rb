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
    attr_accessor :name
    attr_accessor :resource_definition
    attr_accessor :routing_config

    def self.update_attribute(attribute, options, block)
      attribute.options.merge!(options)
      attribute.type.attributes(options, &block)
    end

    def initialize(name, resource_definition, media_type:nil, **opts, &block)
      # TODO: I think we can get away without a name...and just storing the
      # configuration (RestfulSinatraApplicationConfig.action already keys this
      # config off of the action name)
      @name = name
      @resource_definition = resource_definition
      @responses = Set.new
      @response_groups = Set.new
      @attribute_class = opts[:attribute_class] || Attributor::Attribute

      if (media_type = resource_definition.media_type)
        @reference_media_type = media_type if media_type < Praxis::MediaType
      end

      x,y,z = resource_definition.params
      params(x,y,&z) if resource_definition.params

      x,y,z = resource_definition.payload
      payload(x,y,&z) if resource_definition.payload

      x,z = resource_definition.headers
      headers(x,&z) if resource_definition.headers

      self.instance_eval(&block) if block_given?
    end

    def responses(*responses)
      @responses.merge(responses)
    end

    def response_groups(*response_groups)
      @response_groups.merge(response_groups)
    end

    def allowed_responses
      names = @responses + resource_definition.responses
      groups = @response_groups + resource_definition.response_groups

      @allowed_responses = ApiDefinition.instance.responses(names: names, groups: groups)
    end

    def create_attribute(type=Attributor::Struct, **opts, &block)
      unless opts[:reference]
        opts[:reference] = @reference_media_type if @reference_media_type && block
      end

      return @attribute_class.new(type, opts, &block)
    end
    private :create_attribute

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
        self.class.update_attribute(@params, opts, block)
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
        self.class.update_attribute(@payload, opts, block)
      else
        @payload = create_attribute(type, **opts, &block)
      end
    end

    def headers(**opts, &block)
      return @headers unless block

      if @headers
        self.class.update_attribute(@headers, opts, block)
      else
        @headers = create_attribute(dsl_compiler: HeadersDSLCompiler, **opts, &block)
      end
    end

    def routing(&block)
      @routing_config = Skeletor::RestfulRoutingConfig.new(name, resource_definition, &block)
    end

    def description(text = nil)
      @description = text if text
      @description
    end

    def describe
      {}.tap do |hash|
        hash[:description] = description
        hash[:name] = name
        hash[:urls] = routing_config.describe
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
