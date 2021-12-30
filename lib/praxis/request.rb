# frozen_string_literal: true
module Praxis
  class Request < Praxis.request_superclass
    attr_reader :env, :query
    attr_accessor :route_params, :action, :headers, :params, :payload

    PATH_VERSION_PREFIX = '/v'.freeze
    CONTENT_TYPE_NAME = 'CONTENT_TYPE'.freeze
    PATH_INFO_NAME = 'PATH_INFO'.freeze
    REQUEST_METHOD_NAME = 'REQUEST_METHOD'.freeze
    QUERY_STRING_NAME = 'QUERY_STRING'.freeze
    API_VERSION_HEADER_NAME = 'HTTP_X_API_VERSION'.freeze
    API_VERSION_PARAM_NAME = 'api_version'.freeze
    API_NO_VERSION_NAME = 'n/a'.freeze
    VERSION_USING_DEFAULTS = %i[header params].freeze

    def initialize(env)
      @env = env
      @query = Rack::Utils.parse_nested_query(env[QUERY_STRING_NAME])
      @route_params = {}
    end

    # Determine the content type of this request as indicated by the Content-Type header.
    #
    # @return [nil,MediaTypeIdentifier] nil if the header is missing, else a media-type identifier
    def content_type
      header = @env[CONTENT_TYPE_NAME]
      @content_type ||= (header && MediaTypeIdentifier.load(header)).freeze
    end

    # The media type (type/subtype+suffix) portion of the Content-Type
    # header without any media type parameters. e.g., when Content-Type
    # is "text/plain;charset=utf-8", the media-type is "text/plain".
    #
    # For more information on the use of media types in HTTP, see:
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7
    #
    # @return [String]
    # @see MediaTypeIdentifier#without_parameters
    def media_type
      content_type.without_parameters.to_s
    end

    def path
      @env[PATH_INFO_NAME]
    end

    def params_hash
      return {} if params.nil?

      params.attributes
    end

    def verb
      @env[REQUEST_METHOD_NAME]
    end

    def raw_params
      @raw_params ||= begin
        params = query.merge(route_params)
        params.delete(API_VERSION_PARAM_NAME)
        params
      end
    end

    def raw_payload
      @raw_payload ||= if (input = env['rack.input'.freeze].read)
                         env['rack.input'.freeze].rewind
                         input
                       end
    end

    def coalesce_inputs!
      raw_params
      raw_payload
    end

    def self.path_version_prefix
      PATH_VERSION_PREFIX
    end

    # DEPRECATED: remove with EndpointDefinition.version using: :path
    PATH_VERSION_MATCHER = %r{^#{path_version_prefix}(?<version>[^/]+)/}.freeze

    def path_version_matcher
      if Application.instance.versioning_scheme == :path
        matcher = Mustermann.new(ApiDefinition.instance.info.base_path + '*')
        matcher.params(path)[API_VERSION_PARAM_NAME]
      else
        PATH_VERSION_MATCHER.match(path)[:version]
      end
    end

    def version
      result = nil

      Array(Application.instance.versioning_scheme).find do |mode|
        case mode
        when :header
          result = env[API_VERSION_HEADER_NAME]
        when :params
          result = @query[API_VERSION_PARAM_NAME]
        when :path
          result = path_version_matcher
        else
          raise "Unknown method for retrieving the API version: #{mode}"
        end
      end
      result || API_NO_VERSION_NAME
    end

    def load_headers(context)
      return unless action.headers

      defined_headers = action.precomputed_header_keys_for_rack.each_with_object({}) do |(upper, original), hash|
        hash[original] = env[upper] if env.has_key? upper
      end
      self.headers = action.headers.load(defined_headers, context)
    end

    def load_params(context)
      return unless action.params

      self.params = action.params.load(raw_params, context)
    end

    def load_payload(context)
      return unless action.payload
      return if content_type.nil?

      raw = if (handler = Praxis::Application.instance.handlers[content_type.handler_name])
              handler.parse(raw_payload)
            else
              # TODO: is this a good default?
              raw_payload
            end

      self.payload = action.payload.load(raw, context, content_type: content_type.to_s)
    end

    def validate_headers(context)
      return [] unless action.headers

      return ["Attribute #{Attributor.humanize_context(context)} is required."] if action.headers.options[:required] == true && headers.nil?

      action.headers.validate(headers, context)
    end

    def validate_params(context)
      return [] unless action.params

      return ["Attribute #{Attributor.humanize_context(context)} is required."] if action.params.options[:required] == true && params.nil?

      action.params.validate(params, context)
    end

    def validate_payload(context)
      return [] unless action.payload

      return ["Attribute #{Attributor.humanize_context(context)} is required."] if action.payload.options[:required] == true && payload.nil?

      action.payload.validate(payload, context)
    end

    # versions that matched all the conditions of the request (except its version)
    def unmatched_versions
      @unmatched_versions ||= Set.new
    end

    # Override the inspect instance method of a request, as, by default, the kernel inspect will go nuts
    # traversing the action and app_instance and therefore all associated instance variables reachable through that
    def inspect
      "'@env' => #{@env.inspect},\n'@headers' => #{@headers.inspect},\n'@params' => #{@params.inspect},\n'@query' => #{@query.inspect}"
    end
  end
end
