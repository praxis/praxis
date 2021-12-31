# frozen_string_literal: true

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

    def define(key = nil, type = Attributor::Struct, **opts, &block)
      raise Exceptions::InvalidConfiguration, "You cannot define the top level configuration with a non-Struct type. Got: #{type.inspect}" if key.nil? && type != Attributor::Struct

      case key
      when String, Symbol, NilClass

        top = key.nil? ? @attribute : @attribute.attributes[key]
        if top # key defined...redefine
          raise Exceptions::InvalidConfiguration, "Incompatible type received for extending configuration key [#{key}]. Got type #{type.name}" unless type == Attributor::Struct && top.type < Attributor::Struct

          top.options.merge!(opts)
          top.type.attributes(**opts, &block)
        else
          @attribute.attributes[key] = Attributor::Attribute.new(type, opts, &block)
        end
      else
        raise Exceptions::InvalidConfiguration, "Defining a configuration key requires a String or a Symbol key. Got: #{key.inspect}"
      end
    end

    def set(config)
      context = %w[Application config]

      begin
        @value = @attribute.load(config, context, recurse: true)
      rescue Attributor::AttributorException => e
        raise Exceptions::ConfigLoad.new(exception: e)
      end

      errors = @attribute.validate(@value, context)

      raise Exceptions::ConfigValidation.new(errors: errors) unless errors.empty?
    end

    def get
      @value ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
        context = %w[Application config].freeze
        @attribute.load({}, context, recurse: true)
      end
    end
  end
end
