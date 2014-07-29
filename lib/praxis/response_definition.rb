
module Praxis
  # Response spec DSL container
  
  class ResponseDefinition
    attr_reader :name, :group

    def initialize(response_name, group: :default, **spec, &block)
      raise "NO NAME!!!" unless response_name
      @spec = {}
      @group = group
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
        when :controller_defined
          media_type
        else
          raise "Invalid media_type specification. media_type must be a String, MediaType or :controller_defined"
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

    def parts
      
    end
#   def multipart(mode=nil, &block)
#     return @spec[:multipart] if mode.nil?
#
#     unless [:always, :optional].include?(mode)
#       raise "Invalid multipart mode: #{mode}. Valid values are: :always or :optional"
#     end
#     @spec[:multipart] = ResponseDefinition.new(mode, {status:200}, &block)
#   end

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
  end
end
