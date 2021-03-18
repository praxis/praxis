
module Praxis
  # Response spec DSL container

  class ResponseDefinition
    attr_reader :name

    def initialize(response_name, **spec, &block)
      unless response_name
        raise Exceptions::InvalidConfiguration.new(
          "Response name is required for a response specification"
        )
      end
      @spec = { headers:{} }
      @name = response_name
      self.instance_exec(**spec, &block) if block_given?

      if self.status.nil?
        raise Exceptions::InvalidConfiguration.new(
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
        if media_type < Praxis::Types::MediaTypeCommon
          media_type
        else
          raise Exceptions::InvalidConfiguration.new(
            'Invalid media_type specification. media_type must be a Praxis::MediaType'
          )
        end
      when SimpleMediaType
        media_type
      else
        raise Exceptions::InvalidConfiguration.new(
          'Invalid media_type specification. media_type must be a String, MediaType or SimpleMediaType'
        )
      end
    end

    def location(loc=nil, description: nil)
      return  @spec[:headers].dig('Location',:value) if loc.nil?

      header(name: 'Location', value: loc, description: description)
    end

    def headers(hdrs = nil)
      return @spec[:headers] if hdrs.nil?

      case hdrs
      when Array
        hdrs.each {|h| 
          headers(h)
        }
      when Hash
        hdrs.each {|(header_name, header_value)| 
          header(name: header_name, value: header_value)
        }
      when String
        header(name: hdrs, value: nil)
      else
        raise Exceptions::InvalidConfiguration.new(
          "Invalid headers specification: Arrays, Hash, or String must be used. Received: #{hdrs.inspect}"
        )
      end
    end

    def get_header(name)
      @spec[:headers][name]
    end

    # header setter
    def header(name:, value: nil, description: nil)
      the_type = case value
      when nil,String
        String
      when Regexp
        Regexp
      else
        raise Exceptions::InvalidConfiguration.new(
          "A header definition for a response can only take String, Regexp or nil values (to match anything)." +
          "Received the following value for header name #{name}: #{value}"
        )
      end

      info = { 
        value: value, 
        attribute: Attributor::Attribute.new(the_type)
      }
      info[:description] = description if description
      @spec[:headers][name] = info
    end

    def example(context=nil)
      return nil if self.media_type.nil?
      return nil if self.media_type.kind_of?(SimpleMediaType)

      if context.nil?
        context = "#{self.media_type.name}-#{self.name}"
      end

      self.media_type.example(context)
    end


    def describe(context: nil)
      location_type = location.is_a?(Regexp) ? :regexp : :string
      location_value = location.is_a?(Regexp) ? location.inspect : location
      content = {
        :description => description,
        :status => status,
        :headers => {}
      }

      unless headers == nil
        headers.each do |name, value|
          content[:headers][name] = _describe_header(value)
        end
      end
      content[:location] = content[:headers]['Location']


      if self.media_type
        payload = media_type.describe(true)

        if (example_payload = self.example(context))
          payload[:examples] = {}
          rendered_payload = example_payload.dump

          # FIXME: remove load when when MediaTypeCommon.identifier returns a MediaTypeIdentifier
          identifier = MediaTypeIdentifier.load(self.media_type.identifier)

          default_handlers = ApiDefinition.instance.info.produces

          handlers = Praxis::Application.instance.handlers.select do |k,v|
            default_handlers.include?(k)
          end

          if (identifier && handler = handlers[identifier.handler_name])
            payload[:examples][identifier.handler_name] = {
              content_type: identifier.to_s,
              body: handler.generate(rendered_payload)
            }
          else
            handlers.each do |name, handler|
              content_type = ( identifier ) ? identifier + name : 'application/' + name
              payload[:examples][name] = {
                content_type: content_type.to_s,
                body: handler.generate(rendered_payload)
              }
            end
          end
        end

        content[:payload] = {type: payload}
      end

      unless parts == nil
        content[:parts_like] = parts.describe
      end
      content
    end

    def _describe_header(data)

      data_type = data[:value].is_a?(Regexp) ? :regexp : :string
      data_value = data[:value].is_a?(Regexp) ? data[:value].inspect : data[:value]
      { :value => data_value, :type => data_type }
    end

    def validate(response, validate_body: false)
      validate_status!(response)
      validate_headers!(response)
      validate_content_type!(response)
      validate_parts!(response)

      if validate_body
        validate_body!(response)
      end
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
    # @raise [Exceptions::Validation]  When response returns an unexpected status.
    #
    def validate_status!(response)
      return unless status
      # Validate status code if defined in the spec
      if response.status != status
        raise Exceptions::Validation.new(
          "Invalid response code detected. Response %s dictates status of %s but this response is returning %s." %
          [name, status.inspect, response.status.inspect]
        )
      end
    end

    # Validates Headers
    #
    # @raise [Exceptions::Validation]  When there is a missing required header..
    #
    def validate_headers!(response)
      return unless headers
      headers.each do |name, value|
        if name.is_a? Symbol
          raise Exceptions::Validation.new(
            "Symbols are not supported in headers"
          )
        end

        unless response.headers.has_key?(name)
          raise Exceptions::Validation.new(
            "Header #{name.inspect} was required but is missing"
          )
        end

        errors = value[:attribute].validate(response.headers[name])

        unless errors.empty? 
          raise Exceptions::Validation.new("Header #{name.inspect}, with value #{value.inspect} does not match #{response.headers[name]}.")
        end
        # case value
        # when String
        #   if response.headers[name] != value
        #     raise Exceptions::Validation.new(
        #       "Header #{name.inspect}, with value #{value.inspect} does not match #{response.headers[name]}."
        #     )
        #   end
        # when Regexp
        #   if response.headers[name] !~ value
        #     raise Exceptions::Validation.new(
        #       "Header #{name.inspect}, with value #{value.inspect} does not match #{response.headers[name].inspect}."
        #     )
        #   end
        # end
      end
    end


    # Validates Content-Type header and response media type
    #
    # @param [Object] response
    #
    # @raise [Exceptions::Validation] When there is a missing required header
    #
    def validate_content_type!(response)
      return unless media_type

      response_content_type = response.content_type
      expected_content_type = Praxis::MediaTypeIdentifier.load(media_type.identifier)

      unless expected_content_type.match(response_content_type)
        raise Exceptions::Validation.new(
          "Bad Content-Type header. #{response_content_type}" +
          " is incompatible with #{expected_content_type} as described in response: #{self.name}"
        )
      end
    end

    # Validates response body
    #
    # @param [Object] response
    #
    # @raise [Exceptions::Validation]  When there is a missing required header..
    def validate_body!(response)
      return unless media_type
      return if media_type.kind_of? SimpleMediaType

      errors = self.media_type.validate(self.media_type.load(response.body))
      if errors.any?
        message = "Invalid response body for #{media_type.identifier}." +
          "Errors: #{errors.inspect}"
          raise Exceptions::Validation.new(message, errors: errors)
      end

    end

    def validate_parts!(response)
      return unless parts

      response.body.each do |part|
        parts.validate(part)
      end
    end

  end
end
