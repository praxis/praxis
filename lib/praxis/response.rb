
module Praxis
  class Response

    attr_accessor :name, :status, :headers, :body, :request

    class << self
      attr_accessor :response_name
    end

    def self.definition
      ApiDefinition.instance.response(self.response_name)
    end

    def definition
      self.class.definition
    end

    def response_name
      self.class.response_name
    end

    def initialize(status:200, headers:{}, body:'')
      @name    = response_name
      @status  = status
      @headers = headers
      @body    = body
    end

    def to_rack
      case @body
      when Hash
        @body = JSON.pretty_generate(@body)
      end

      @body = Array(body)
      [@status, @headers, @body]
    end


    # Validates the response
    #
    # @param [Object] action
    #
    def validate(action)
      validate_status!
      validate_location!
      validate_headers!
      validate_content_type_and_media_type!(action)
    end


    # Validates Status code
    #
    # @raise [RuntimeError]  When response returns an unexpected status.
    #
    def validate_status!
      return unless definition.status
      # Validate status code if defined in the spec
      if definition.status != status
        fail "Invalid response code detected. Response %s dictates status of %s but this response is returning %s." %
             [definition.name, definition.status, status]
      end
    end


    # Validates 'Location' header
    #
    # @raise [RuntimeError]  When location heades does not match to the defined one.
    #
    def validate_location!
      location = definition.location
      return unless location
      # Validate location
      case location
      when Regexp
        matches = location =~ headers['Location']
        fail "LOCATION does not match regexp #{location.inspect}!" unless matches
      when String
        matches = location == headers['Location']
        fail "LOCATION does not match string #{location}!" unless matches
      else
        fail "Unknown location spec"
      end
    end


    # Validates Headers
    #
    # @raise [RuntimeError]  When there is a missing required header..
    #
    def validate_headers!
      definition_headers = definition.headers
      return unless definition_headers
      # Validate headers
      definition_headers = [ definition_headers ] unless definition_headers.is_a?(Array)
      definition_headers.each do |h|
        valid = false
        case h
        when Hash   then  valid = h.all? { |k, v| headers.has_key?(k) && headers[k] == v }
        when String then  valid = headers.has_key?(h)
        when Symbol then  fail "Symbols are not supported"
        end
        fail "headers missing" unless valid
      end
    end


    # Validates Content-Type header and response media type
    #
    # @param [Object] action
    #
    # @raise [RuntimeError]  When there is a missing required header..
    #
    def validate_content_type_and_media_type!(action)
      media_type = definition.media_type
      return unless media_type

      resource_definition  = action.resource_definition
      # Support "+json" and options like ";type=collection"
      extracted_identifier = headers['Content-Type'] && headers['Content-Type'].split('+').first.split(';').first

      # Handle :controller_defined special case
      if media_type == :controller_defined
        media_type = resource_definition.media_type
        unless media_type
          fail "Error validating content type: this controller (#{resource_definition}) "+
               "doesn't have any associated media_type"
        end
      end

      if media_type.identifier != extracted_identifier
        fail "Bad Content-Type: returned type #{extracted_identifier} does not match "+
             "type #{media_type.identifier} as described in response: #{definition.name}"
      end
    end

  end
end
