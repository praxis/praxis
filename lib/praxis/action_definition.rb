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
    attr_reader :name, :endpoint_definition, :api_definition, :route, :responses, :traits

    # opaque hash of user-defined medata, used to decorate the definition,
    # and also available in the generated JSON documents
    attr_reader :metadata

    class << self
      attr_accessor :doc_decorations
    end

    @doc_decorations = []

    def self.decorate_docs(&callback)
      doc_decorations << callback
    end

    def initialize(name, endpoint_definition, **_opts, &block)
      @name = name
      @endpoint_definition = endpoint_definition
      @responses = {}
      @metadata = {}
      @route = nil
      @traits = []

      if (media_type = endpoint_definition.media_type) && (media_type.is_a?(Class) && media_type < Praxis::Types::MediaTypeCommon)
        @reference_media_type = media_type
      end

      version = endpoint_definition.version
      api_info = ApiDefinition.instance.info(endpoint_definition.version)

      route_base = "#{api_info.base_path}#{endpoint_definition.version_prefix}"
      prefix = Array(endpoint_definition.routing_prefix)

      @routing_config = RoutingConfig.new(version: version, base: route_base, prefix: prefix)

      endpoint_definition.traits.each do |trait|
        self.trait(trait)
      end

      endpoint_definition.action_defaults.apply!(self)

      instance_eval(&block) if block_given?
    end

    def trait(trait_name)
      raise Exceptions::InvalidTrait, "Trait #{trait_name} not found in the system" unless ApiDefinition.instance.traits.has_key? trait_name

      trait = ApiDefinition.instance.traits.fetch(trait_name)
      trait.apply!(self)
      traits << trait_name
    end

    def update_attribute(attribute, options, block)
      attribute.options.merge!(options)
      attribute.type.attributes(**options, &block)
    end

    def response(name, type = nil, **args, &block)
      if type
        # should verify type is a media type

        type = type.construct(block) if block_given?

        args[:media_type] = type
      end

      template = ApiDefinition.instance.response(name)
      @responses[name] = template.compile(self, **args)
    end

    def create_attribute(type = Attributor::Struct, **opts, &block)
      opts[:reference] = @reference_media_type if !opts.key?(:reference) && (@reference_media_type && block)

      Attributor::Attribute.new(type, opts, &block)
    end

    def params(type = Attributor::Struct, **opts, &block)
      return @params if !block && (opts.nil? || opts.empty?) && type == Attributor::Struct

      unless opts.key? :required
        opts[:required] = true # Make the payload required by default
      end

      if @params
        raise Exceptions::InvalidConfiguration, "Invalid type received for extending params: #{type.name}" unless type == Attributor::Struct && @params.type < Attributor::Struct

        update_attribute(@params, opts, block)
      else
        @params = create_attribute(type, **opts, &block)
      end

      @params
    end

    def payload(type = Attributor::Struct, **opts, &block)
      return @payload if !block && (opts.nil? || opts.empty?) && type == Attributor::Struct

      unless opts.key?(:required)
        opts = { required: true, null: false }.merge(opts) # Make the payload required and non-nullable by default
      end

      if @payload
        raise Exceptions::InvalidConfiguration, "Invalid type received for extending params: #{type.name}" unless type == Attributor::Struct && @payload.type < Attributor::Struct

        update_attribute(@payload, opts, block)
      else
        @payload = create_attribute(type, **opts, &block)
      end
    end

    def headers(type = nil, **opts, &block)
      return @headers unless block

      unless opts.key? :required
        opts[:required] = true # Make the payload required by default
      end

      if @headers
        update_attribute(@headers, opts, block)
      else
        type ||= Attributor::Hash.of(key: String)
        @headers = create_attribute(type,
                                    dsl_compiler: HeadersDSLCompiler, case_insensitive_load: true,
                                    **opts, &block)

        @headers
      end
      @precomputed_header_keys_for_rack = nil # clear memoized data
    end

    # Good optimization to avoid creating lots of strings and comparisons
    # on a per-request basis.
    # However, this is hacky, as it is rack-specific, and does not really belong here
    def precomputed_header_keys_for_rack
      @precomputed_header_keys_for_rack ||= @headers.attributes.keys.each_with_object({}) do |key, hash|
        name = key.to_s
        name = "HTTP_#{name.gsub('-', '_').upcase}" unless %w[CONTENT_TYPE CONTENT_LENGTH].include?(name)
        hash[name] = key
      end
    end

    def routing(&block)
      @routing_config.instance_eval(&block)

      @route = @routing_config.route
    end

    def description(text = nil)
      @description = text if text
      @description
    end

    def self.url_description(route:, params_example:, params:)
      route_description = route.describe

      example_hash = params_example ? params_example.dump : {}
      hash = route.example(example_hash: example_hash, params: params)

      query_string = URI.encode_www_form(hash[:query_params])
      url = hash[:url]
      url = [url, query_string].join('?') unless query_string.empty?

      route_description[:example] = url
      route_description
    end

    def describe(context: nil)
      {}.tap do |hash|
        hash[:description] = description
        hash[:name] = name
        hash[:metadata] = metadata
        if headers
          headers_example = headers.example(context)
          hash[:headers] = headers_description(example: headers_example)
        end
        if params
          params_example = params.example(context)
          hash[:params] = params_description(example: params_example)
        end
        if payload
          payload_example = payload.example(context)

          hash[:payload] = payload_description(example: payload_example)
        end

        hash[:responses] = responses.each_with_object({}) do |(_response_name, response), memo|
          memo[response.name] = response.describe(context: context)
        end
        hash[:traits] = traits if traits.any?
        # FIXME: change to :routes along with api browser
        # FIXME: change urls to url ... (along with the browser)
        hash[:urls] = [ActionDefinition.url_description(route: route, params: params, params_example: params_example)]
        self.class.doc_decorations.each do |callback|
          callback.call(self, hash)
        end
      end
    end

    def headers_description(example:)
      output = headers.describe(example: example)
      required_headers = headers.attributes.select { |_k, attr| attr.options && attr.options[:required] == true }
      output[:example] = required_headers.each_with_object({}) do |(name, _attr), hash|
        hash[name] = example[name].to_s # Some simple types (like Boolean) can be used as header values, but must convert back to s
      end
      output
    end

    def params_description(example:)
      route_params = []
      if route.nil?
        warn "Warning: No route defined for #{endpoint_definition.name}##{name}."
      else
        route_params = route.path
                            .named_captures
                            .keys
                            .collect(&:to_sym)
      end

      desc = params.describe(example: example)
      desc[:type][:attributes].keys.each do |k|
        source = if route_params.include? k
                   'url'
                 else
                   'query'
                 end
        desc[:type][:attributes][k][:source] = source
      end
      required_params = desc[:type][:attributes].select { |_k, v| v[:source] == 'query' && v[:required] == true }.keys
      phash = required_params.each_with_object({}) do |name, hash|
        hash[name] = example[name]
      end
      desc[:example] = URI.encode_www_form(phash)
      desc
    end

    # Determine the content_type to report for a given example,
    # using handler_name if possible.
    #
    # Considers any pre-defined set of values on the content_type attributge
    # of the headers.
    def derive_content_type(example, handler_name)
      # MultipartArrays *must* use the provided content_type
      return MediaTypeIdentifier.load(example.content_type) if example.is_a? Praxis::Types::MultipartArray

      _, content_type_attribute = headers && headers.attributes.find { |k, _v| k.to_s =~ /^content[-_]{1}type$/i }
      if content_type_attribute && content_type_attribute.options.key?(:values)

        # if any defined value match the preferred handler_name, return it
        content_type_attribute.options[:values].each do |ct|
          mti = MediaTypeIdentifier.load(ct)
          return mti if mti.handler_name == handler_name
        end

        # otherwise, pick the first
        pick = MediaTypeIdentifier.load(content_type_attribute.options[:values].first)

        # and return that one if it already corresponds to a registered handler
        # otherwise, add the encoding
        if Praxis::Application.instance.handlers.include?(pick.handler_name)
          return pick
        else
          return pick + handler_name
        end
      end

      # generic default encoding
      MediaTypeIdentifier.load("application/#{handler_name}")
    end

    def payload_description(example:)
      hash = payload.describe(example: example)

      hash[:examples] = {}

      default_handlers = ApiDefinition.instance.info.consumes

      default_handlers.each do |default_handler|
        dumped_payload = payload.dump(example, default_format: default_handler)

        content_type = derive_content_type(example, default_handler)
        handler = Praxis::Application.instance.handlers[content_type.handler_name]

        # in case handler is nil, use dumped_payload as-is.
        generated_payload = if handler.nil?
                              dumped_payload
                            else
                              handler.generate(dumped_payload)
                            end

        hash[:examples][default_handler] = {
          content_type: content_type.to_s,
          body: generated_payload
        }
      end

      hash
    end

    def nodoc!
      metadata[:doc_visibility] = :none
    end

    # [DEPRECATED] - Warn of the change of method name for the transition
    def resource_definition
      raise 'Praxis::ActionDefinition does not use `resource_definition` any longer. Use `endpoint_definition` instead.'
    end
  end
end
