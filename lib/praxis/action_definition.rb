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
    attr_reader :responses

    def initialize(name, resource_definition, **opts, &block)
      @name = name
      @resource_definition = resource_definition
      @responses = Hash.new

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

      resource_definition.responses.each do |name, args|
        response(name, args)
      end

      self.instance_eval(&block) if block_given?
    end

    def update_attribute(attribute, options, block)
      attribute.options.merge!(options)
      attribute.type.attributes(options, &block)
    end

    def response( name, **args )
      template = ApiDefinition.instance.response(name)
      @responses[name] = template.compile(self, **args)
    end

    def create_attribute(type=Attributor::Struct, **opts, &block)
      unless opts[:reference]
        opts[:reference] = @reference_media_type if @reference_media_type && block
      end

      return Attributor::Attribute.new(type, opts, &block)
    end

    def use(trait_name)
      unless ApiDefinition.instance.traits.has_key? trait_name
        raise Exceptions::InvalidTrait.new("Trait #{trait_name} not found in the system")
      end
      self.instance_eval(&ApiDefinition.instance.traits[trait_name])
    end

    def params(type=Attributor::Struct, **opts, &block)
      return @params if !block && type == Attributor::Struct

      if @params
        unless type == Attributor::Struct && @params.type < Attributor::Struct
          raise Exceptions::InvalidConfiguration.new(
            "Invalid type received for extending params: #{type.name}"
          )
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
          raise Exceptions::InvalidConfiguration.new(
            "Invalid type received for extending params: #{type.name}"
          )
        end
        update_attribute(@payload, opts, block)
      else
        @payload = create_attribute(type, **opts, &block)
      end
    end

    def headers(type=Attributor::Hash.of(key:String), **opts, &block)
      return @headers unless block
      if @headers
        update_attribute(@headers, opts, block)
      else
        @headers = create_attribute(type,
          dsl_compiler: HeadersDSLCompiler, case_insensitive_load: true, 
          **opts, &block)
      end
      @precomputed_header_keys_for_rack = nil #clear memoized data
    end

    # Good optimization to avoid creating lots of strings and comparisons
    # on a per-request basis.
    # However, this is hacky, as it is rack-specific, and does not really belong here
    def precomputed_header_keys_for_rack
      @precomputed_header_keys_for_rack ||= begin
        @headers.attributes.keys.each_with_object(Hash.new) do |key,hash|
          name = key.to_s
          name = "HTTP_#{name.gsub('-','_').upcase}" unless ( name == "CONTENT_TYPE" || name == "CONTENT_LENGTH" )
          hash[name] = key
        end
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
        hash[:responses] = responses.inject({}) do |memo, (response_name, response)|
          memo[response.name] = response.describe
          memo
        end
      end
    end

  end
end
