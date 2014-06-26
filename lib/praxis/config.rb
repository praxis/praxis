module Praxis
  class Config
    include Attributor::Type

    def initialize
      @definition = Attributor::Attribute.new(Attributor::Struct) {}
      @value = nil
    end

    def define(&block)
      @definition.type.attributes({}, &block)
    end

    def set(config)
      context = ['Application', 'config']

      begin
        @value = @definition.load(config, context)
      rescue Attributor::AttributorException => e
        fail Exceptions::ConfigLoadException.new(exception: e)
      end

      errors = @definition.validate(@value, context)

      unless errors.empty?
        fail Exceptions::ConfigValidationException.new(errors: errors)
      end
    end

    def get
      @value
    end
  end
end
