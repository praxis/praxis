module Praxis
  class Config
    include Attributor::Type

    attr_reader :attribute

    def initialize
      @attribute = Attributor::Attribute.new(Attributor::Struct) {}
      @value = nil
    end

    def define(&block)
      @attribute.type.attributes({}, &block)
    end

    def set(config)
      context = ['Application', 'config']

      begin
        @value = @attribute.load(config, context)
      rescue Attributor::AttributorException => e
        raise Exceptions::ConfigLoadException.new(exception: e)
      end

      errors = @attribute.validate(@value, context)

      unless errors.empty?
        raise Exceptions::ConfigValidationException.new(errors: errors)
      end
    end

    def get
      @value
    end
    
  end
end
