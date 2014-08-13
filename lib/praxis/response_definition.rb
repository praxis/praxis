
module Praxis
  # Response spec DSL container

  class ResponseDefinition
    attr_reader :name

    def initialize(response_name, **spec, &block)
      raise "NO NAME!!!" unless response_name
      @spec = { headers:{} }
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
            
      case hdrs
      when Array
        hdrs.each {|header_name| header(header_name) }
      when Hash
        header(hdrs)
      when String
        header(hdrs)
      else
        raise "Invalid headers specification: Arrays, Hash, or String must be used. Got: #{hdrs.inspect}"
      end
    end
    
    def header(hdr)
      case hdr
      when String
        @spec[:headers][hdr] = true
      when Hash
        hdr.each do | k, v |
          unless v.is_a?(Regexp) || v.is_a?(String)
            raise "Header definitions for #{k.inspect} can only match values of type String or Regexp. Got: #{v.inspect}"
          end
          @spec[:headers][k] = v
       end
      else
        raise "A header definition can only take a String (to match the name) or a Hash (to match both the name and the value). Got: #{hdr.inspect}"
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
    # @raise [RuntimeError]  When response returns an unexpected status.
    #
    def validate_status!(response)
      return unless status
      # Validate status code if defined in the spec
      if response.status != status
        raise "Invalid response code detected. Response %s dictates status of %s but this response is returning %s." %
        [name, status.inspect, response.status.inspect]
      end
    end


    # Validates 'Location' header
    #
    # @raise [RuntimeError]  When location header does not match to the defined one.
    #
    def validate_location!(response)
      return if location.nil? || location === response.headers['Location']
      raise "LOCATION does not match to #{location.inspect}!"
    end


    # Validates Headers
    #
    # @raise [RuntimeError]  When there is a missing required header..
    #
    def validate_headers!(response)
      return unless headers
      headers.each do |name, value|
        raise "Symbols are not supported" if name.is_a? Symbol
        raise "header #{name.inspect} was requred but it is missing" unless response.headers.has_key?(name)

        case value
        when String
          if response.headers[name] != value
            raise "header #{name.inspect}, with value #{value.inspect} does not match #{response.headers[name]}." unless valid
          end
        when Regexp
          if response.headers[name] !~ value
            raise "header #{name.inspect}, with value #{value.inspect} does not match #{response.headers[name].inspect}." unless valid          
          end
        end          
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

    def validate_parts!(response)
      return unless parts

      response.parts.each do |name, part|
        parts.validate(part)
      end

    end

  end
end
