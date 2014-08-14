
module Praxis
  # Response spec DSL container

  class ResponseDefinition
    attr_reader :name

    def initialize(response_name, **spec, &block)
      unless response_name
        raise Exceptions::InvalidConfigurationException.new(
          "Response name is required for a response specification"
        )
      end
      @spec = { headers:{} }
      @name = response_name
      self.instance_exec(**spec, &block) if block_given?

      if self.status.nil?
        raise Exceptions::InvalidConfigurationException.new(
          "Status code is required for a response specification"
        )
      end
    end

    def description(text=nil)
      return @spec[:description] if text.nil?
      @spec[:description] = text
    end

    def status(code=nil)
      return @spec[:status] if code.nil?
      @spec[:status] = code
    end

    def media_type(media_type=nil)
      return @spec[:media_type] if media_type.nil?

      @spec[:media_type] = case media_type
        when String
          SimpleMediaType.new(media_type)
        when Class
          if media_type < Praxis::MediaType
            media_type
          else
            raise Exceptions::InvalidConfigurationException.new(
              'Invalid media_type specification. media_type must be a Praxis::MediaType'
            )
          end
        when SimpleMediaType
          media_type
        else
          raise Exceptions::InvalidConfigurationException.new(
            'Invalid media_type specification. media_type must be a String, MediaType or SimpleMediaType'
          )
        end
    end

    def location(loc=nil)
      return @spec[:location] if loc.nil?
      unless ( loc.is_a?(Regexp) || loc.is_a?(String) )
        raise Exceptions::InvalidConfigurationException.new(
          "Invalid location specification. Location in response must be either a regular expression or a string."
        )
      end
      @spec[:location] = loc
    end

    def headers(hdrs = nil)
      return @spec[:headers] if hdrs.nil?

      case hdrs
      when Array
        hdrs.each {|header_name| header(header_name) }
      when Hash
        header(hdrs)
      when String
        header(hdrs)
      else
        raise Exceptions::InvalidConfigurationException.new(
          "Invalid headers specification: Arrays, Hash, or String must be used. Received: #{hdrs.inspect}"
        )
      end
    end

    def header(hdr)
      case hdr
      when String
        @spec[:headers][hdr] = true
      when Hash
        hdr.each do | k, v |
          unless v.is_a?(Regexp) || v.is_a?(String)
            raise Exceptions::InvalidConfigurationException.new(
              "Header definitions for #{k.inspect} can only match values of type String or Regexp. Received: #{v.inspect}"
            )
          end
          @spec[:headers][k] = v
       end
      else
        raise Exceptions::InvalidConfigurationException.new(
          "A header definition can only take a String (to match the name) or" +
            " a Hash (to match both the name and the value). Received: #{hdr.inspect}"
        )
      end
    end

    def describe
      location_type = location.is_a?(Regexp) ? :regexp : :string
      location_value = location.is_a?(Regexp) ? location.inspect : location
      content = {
        :description => description,
        :status => status,
        :headers => {}
      }
      content[:location] = _describe_header(location) unless location == nil
      # TODO: Change the mime_type key to media_type!!
      if media_type
        content[:media_type] = if media_type.is_a? Symbol
          media_type
        else
          media_type.describe(true) # TODO: is a shallow describe what we want? or just the name?
        end
      end
      unless headers == nil
        headers.each do |name, value|
          content[:headers][name] = _describe_header(value) 
        end
      end
      unless parts == nil
        content[:parts_like] = parts.describe
      end
      content
    end

    def _describe_header(data)
      data_type = data.is_a?(Regexp) ? :regexp : :string
      data_value = data.is_a?(Regexp) ? data.inspect : data
       { :value => data_value, :type => data_type } 
    end

    def validate( response )
      validate_status!(response)
      validate_location!(response)
      validate_headers!(response)
      validate_content_type!(response)
      validate_parts!(response)
    end

    def parts(proc=nil, like: nil,  **args, &block)
      a_proc = proc || block
      if like.nil? && !a_proc
        raise ArgumentError, "Parts definition for response #{name} needs a :like argument or a block/proc" if !args.empty?
        return @parts
      end
       if like && a_proc
        raise ArgumentError, "Parts definition for response #{name} does not allow :like and a block simultaneously"
      end
      if like
         template = ApiDefinition.instance.response(like)
         @parts = template.compile(nil, **args)
       else # block
         @parts = Praxis::ResponseDefinition.new('anonymous', **args, &a_proc)
       end
    end

    # Validates Status code
    #
    # @raise [Exceptions::ValidationException]  When response returns an unexpected status.
    #
    def validate_status!(response)
      return unless status
      # Validate status code if defined in the spec
      if response.status != status
        raise Exceptions::ValidationException.new(
          "Invalid response code detected. Response %s dictates status of %s but this response is returning %s." %
          [name, status.inspect, response.status.inspect]
        )
      end
    end


    # Validates 'Location' header
    #
    # @raise [Exceptions::ValidationException] When location header does not match to the defined one.
    #
    def validate_location!(response)
      return if location.nil? || location === response.headers['Location']
      raise Exceptions::ValidationException.new("LOCATION does not match #{location.inspect}")
    end


    # Validates Headers
    #
    # @raise [Exceptions::ValidationException]  When there is a missing required header..
    #
    def validate_headers!(response)
      return unless headers
      headers.each do |name, value|
        if name.is_a? Symbol
          raise Exceptions::ValidationException.new(
            "Symbols are not supported in headers"
          )
        end

        unless response.headers.has_key?(name)
          raise Exceptions::ValidationException.new(
            "Header #{name.inspect} was required but is missing"
          )
        end

        case value
        when String
          if response.headers[name] != value
            unless valid
              raise Exceptions::ValidationException.new(
                "Header #{name.inspect}, with value #{value.inspect} does not match #{response.headers[name]}."
              )
            end
          end
        when Regexp
          if response.headers[name] !~ value
            unless valid
              raise Exceptions::ValidationException.new(
                "Header #{name.inspect}, with value #{value.inspect} does not match #{response.headers[name].inspect}."
              )
            end
          end
        end
      end
    end


    # Validates Content-Type header and response media type
    #
    # @param [Object] action
    #
    # @raise [Exceptions::ValidationException] When there is a missing required header
    #
    def validate_content_type!(response)
      return unless media_type

      # Support "+json" and options like ";type=collection"
      # FIXME: parse this better
      extracted_identifier = response.headers['Content-Type'] && response.headers['Content-Type'].split('+').first.split(';').first

      if media_type.identifier != extracted_identifier
        raise Exceptions::ValidationException.new(
          "Bad Content-Type header. Returned type #{extracted_identifier}" +
          " does not match type #{media_type.identifier} as described in response: #{self.name}"
        )
      end
    end

    def validate_parts!(response)
      return unless parts

      response.parts.each do |name, part|
        parts.validate(part)
      end

    end

  end
end
