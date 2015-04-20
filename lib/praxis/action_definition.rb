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
    attr_reader :traits

    # opaque hash of user-defined medata, used to decorate the definition,
    # and also available in the generated JSON documents
    attr_reader :metadata

    class << self
      attr_accessor :doc_decorations
    end

    @doc_decorations = []

    def self.decorate_docs(&callback)
      self.doc_decorations << callback
    end

    def initialize(name, resource_definition, **opts, &block)
      @name = name
      @resource_definition = resource_definition
      @responses = Hash.new
      @metadata = Hash.new
      @routes = []
      @traits = []

      if (media_type = resource_definition.media_type)
        if media_type.kind_of?(Class) && media_type < Praxis::Types::MediaTypeCommon
          @reference_media_type = media_type
        end
      end

      version = resource_definition.version
      api_info = ApiDefinition.instance.info(resource_definition.version)

      version_prefix = "#{api_info.base_path}#{resource_definition.version_prefix}"
      prefix = Array(resource_definition.prefix)

      @routing_config = RoutingConfig.new(version: version, base: version_prefix, prefix: prefix)

      resource_definition.traits.each do |trait|
        self.trait(trait)
      end

      resource_definition.action_defaults.apply!(self)

      self.instance_eval(&block) if block_given?
    end

    def trait(trait_name)
      unless ApiDefinition.instance.traits.has_key? trait_name
        raise Exceptions::InvalidTrait.new("Trait #{trait_name} not found in the system")
      end
      
      trait = ApiDefinition.instance.traits.fetch(trait_name)
      trait.apply!(self)
      traits << trait_name
    end
    alias_method :use, :trait

    def update_attribute(attribute, options, block)
      attribute.options.merge!(options)
      attribute.type.attributes(options, &block)
    end

    def response(name, **args)
      template = ApiDefinition.instance.response(name)
      @responses[name] = template.compile(self, **args)
    end

    def create_attribute(type=Attributor::Struct, **opts, &block)
      unless opts[:reference]
        opts[:reference] = @reference_media_type if @reference_media_type && block
      end

      return Attributor::Attribute.new(type, opts, &block)
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
        if (api_info = ApiDefinition.instance.info(resource_definition.version))
          if api_info.base_params
            base_attrs = api_info.base_params.attributes
            @params.attributes.merge!(base_attrs) do |key, oldval, newval|
              oldval
            end
          end
        end
      end

      @params
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

    def headers(type=nil, **opts, &block)
      return @headers unless block
      if @headers
        update_attribute(@headers, opts, block)
      else
        type = Attributor::Hash.of(key:String) unless type
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
      @routing_config.instance_eval &block

      @routes = @routing_config.routes
      @primary_route = @routing_config.routes.first
      @named_routes = @routing_config.routes.each_with_object({}) do |route, hash|
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
        hash[:metadata] = metadata
        # FIXME: change to :routes along with api browser
        hash[:urls] = routes.collect(&:describe)
        hash[:headers] = headers.describe if headers
        if params
          hash[:params] = params_description
        end
        hash[:payload] = payload.describe if payload
        hash[:responses] = responses.inject({}) do |memo, (response_name, response)|
          memo[response.name] = response.describe
          memo
        end
        hash[:traits] = traits if traits.any?

        self.class.doc_decorations.each do |callback|
          callback.call(self, hash)
        end
      end
    end

    def params_description
      route_params = []
      if primary_route.nil?
        warn "Warning: No routes defined for #{resource_definition.name}##{name}."
      else
        route_params = primary_route.path.
          named_captures.
          keys.
          collect(&:to_sym)
      end

      desc = params.describe
      desc[:type][:attributes].keys.each do |k|
        source = if route_params.include? k
          'url'
        else
          'query'
        end
        desc[:type][:attributes][k][:source] = source
      end
      desc
    end

    def nodoc!
      metadata[:doc_visibility] = :none
    end


  end
end
