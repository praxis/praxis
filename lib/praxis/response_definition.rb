
module Praxis
  # Response spec DSL container

  class ResponseDefinition
    attr_reader :name

    def initialize(response_name, **spec, &block)
      raise "NO NAME!!!" unless response_name
      @spec = {}
      @name = response_name
      self.instance_exec(**spec, &block) if block_given?
      raise "Status code is required for a response specification" if self.status.nil?
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
            raise 'Invalid media_type specification. media_type must be a Praxis::MediaType'
          end
        when SimpleMediaType
          media_type
        else
          raise "Invalid media_type specification. media_type must be a String, MediaType or SimpleMediaType"
        end
    end

    def location(loc=nil)
      return @spec[:location] if loc.nil?
      raise "Invalid location specification" unless ( loc.is_a?(Regexp) || loc.is_a?(String) )
      @spec[:location] = loc
    end

    def headers(hdrs = nil)
      return @spec[:headers] if hdrs.nil?
      if !(hdrs.is_a?(Array) || hdrs.is_a?(Hash) || hdrs.is_a?(String))
        raise "Invalid headers specification: Arrays, Hash, or String must be used"
      end
      @spec[:headers] = hdrs
    end

    def describe
      location_type = location.is_a?(Regexp) ? 'regexp' : 'string'
      location_value = location.is_a?(Regexp) ? location.inspect : location
      content = {
        "description" => description,
        "status" => status
      }
      content['location'] = { "value" => location_value, "type" => location_type } unless location == nil
      # TODO: Change the mime_type key to media_type!!
      if media_type
        content['mime_type'] = if media_type.is_a? Symbol
          media_type
        else
          media_type.describe
        end
      end
      content['headers'] = headers unless headers == nil
      content
    end

    def validate( response )
      validate_status!(response)
      validate_location!(response)
      validate_headers!(response)
      validate_content_type!(response)
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
    # @raise [RuntimeError]  When response returns an unexpected status.
    #
    def validate_status!(response)
      return unless status
      # Validate status code if defined in the spec
      if response.status != status
        raise "Invalid response code detected. Response %s dictates status of %s but this response is returning %s." %
        [name, status, response.status]
      end
    end


    # Validates 'Location' header
    #
    # @raise [RuntimeError]  When location heades does not match to the defined one.
    #
    def validate_location!(response)
      return unless location
      # Validate location
      # FIXME: rewrite with ===
      case location
      when Regexp
        matches = location =~ response.headers['Location']
        raise "LOCATION does not match regexp #{location.inspect}!" unless matches
      when String
        matches = location == response.headers['Location']
        raise "LOCATION does not match string #{location}!" unless matches
      else
        raise "Unknown location spec"
      end
    end


    # Validates Headers
    #
    # @raise [RuntimeError]  When there is a missing required header..
    #
    def validate_headers!(response)
      return unless headers
      # Validate headers
      headers = Array(self.headers) #[ definition_headers ] unless definition_headers.is_a?(Array)
      headers.each do |h|
        valid = false
        case h
        when Hash   then  valid = h.all? { |k, v| response.headers.has_key?(k) && response.headers[k] == v }
        when String then  valid = response.headers.has_key?(h)
        when Symbol then  raise "Symbols are not supported"
        end
        raise "headers missing" unless valid
      end
    end


    # Validates Content-Type header and response media type
    #
    # @param [Object] action
    #
    # @raise [RuntimeError]  When there is a missing required header..
    #
    def validate_content_type!(response)
      return unless media_type

      # Support "+json" and options like ";type=collection"
      # FIXME: parse this better
      extracted_identifier = response.headers['Content-Type'] && response.headers['Content-Type'].split('+').first.split(';').first

      if media_type.identifier != extracted_identifier
        raise "Bad Content-Type: returned type #{extracted_identifier} does not match "+
          "type #{media_type.identifier} as described in response: #{self.name}"
          end
    end


  end
end
