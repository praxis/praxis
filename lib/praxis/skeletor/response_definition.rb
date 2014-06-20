
module Praxis
  module Skeletor
    # Response spec DSL container
    class ResponseDefinition
      attr_reader :name

      def initialize(response_name, spec={}, &block)
        @spec = spec
        @name = response_name
        self.instance_eval(&block) if block_given?
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
        
        if media_type.kind_of?(String)
          media_type = SimpleMediaType.new(media_type)
        end

        @spec[:media_type] = media_type
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


      def multipart(mode=nil, &block)
        return @spec[:multipart] if mode.nil?

        unless [:always, :optional].include?(mode)
          raise "Invalid multipart mode: #{mode}. Valid values are: :always or :optional"
        end
        @spec[:multipart] = ResponseDefinition.new(mode, {status:200}, &block)
      end

      def use(name)
        raise "Behavior #{name} not found in the system" unless $behaviors.has_key? name
        puts "USING BEHAVIOR: #{name} out of #{$behaviors.keys.size} available"
        self.instance_eval(&$behaviors[name])
      end

      def describe
        location_type = location.is_a?(Regexp) ? 'regexp' : 'string'
        location_value = location.is_a?(Regexp) ? location.inspect : location
        content = {
          "description" => description,
          "status" => status
        }
        content['location'] = { "value" => location_value, "type" => location_type } unless location == nil
        content['mime_type'] = mime_type unless mime_type == nil
        content['headers'] = headers unless headers == nil
        content
      end
    end
  end
end
