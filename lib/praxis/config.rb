module Praxis
  class Config
    include Attributor::Type

    attr_reader :attribute

    def initialize
      @attribute = Attributor::Attribute.new(Attributor::Struct) {}
      @value = nil
    end

    # You can define the configuration in different ways
    # 
    # Add a key to the top struct
    # define do
    #   attribute :added_to_top, String
    # end
    #
    # Add a key to the top struct (that is a struct itself)
    # define do
    #   attribute :app do
    #     attribute :one String
    #   end
    # end
    # Which you could expand too in this way
    # define do
    #   attribute :app do
    #     attribute :two String
    #   end
    # end
    
    # ...or using this way too (equivalent)
    # define(:app) do
    #   attribute :two, String
    # end
    # You can also define a key to be a non-Struct type
    # define :app, Attributor::Hash
        
    def define(key=nil, type=Attributor::Struct, **opts, &block)
      if key.nil? && type != Attributor::Struct
        raise Exceptions::InvalidConfiguration.new(
          "You cannot define the top level configuration with a non-Struct type. Got: #{type.inspect}"
        )
      end
      
      case key
      when String, Symbol, NilClass

        top = key.nil? ? @attribute : @attribute.attributes[key]
        if top #key defined...redefine
          unless  type == Attributor::Struct && top.type < Attributor::Struct
            raise Exceptions::InvalidConfiguration.new(
              "Incompatible type received for extending configuration key [#{key}]. Got type #{type.name}"
            )
          end
          top.options.merge!(opts)
          top.type.attributes(**opts, &block)
        else
          @attribute.attributes[key] = Attributor::Attribute.new(type, opts, &block)
        end
      else
        raise Exceptions::InvalidConfiguration.new(
          "Defining a configuration key requires a String or a Symbol key. Got: #{key.inspect}"
        )
      end
            
    end

    def set(config)
      context = ['Application', 'config']

      begin
        @value = @attribute.load(config, context, recurse: true)
      rescue Attributor::AttributorException => e
        raise Exceptions::ConfigLoad.new(exception: e)
      end

      errors = @attribute.validate(@value, context)

      unless errors.empty?
        raise Exceptions::ConfigValidation.new(errors: errors)
      end
    end

    def get
      @value ||= begin
        context = ['Application','config'].freeze
        @attribute.load({},context, recurse: true)
      end
    end

  end
end
