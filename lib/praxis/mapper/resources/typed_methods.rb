# frozen_string_literal: true

module Praxis
  module Mapper
    module Resources
      # Error raised when trying to call a typed method and the validation of arguments fails
      class IncompatibleTypeForMethodArguments < ::StandardError
        attr_reader :errors, :method

        def initialize(errors:, method:, klass:)
          @errors = errors
          super "Error validating/coercing arguments for call to method #{method} of class #{klass}:\n#{errors}"
        end
      end

      module TypedMethods
        extend ::ActiveSupport::Concern

        included do
          include Praxis::Mapper::Resources::Callbacks

          class << self
            attr_reader :signatures

            def _finalize!
              if @signatures
                # Build the around callbacks for coercing the params for the methods with types defined
                # Also, this needs to be before, so that we hit the coercion code before any other around callback
                const_set(:MethodSignatures, Module.new)
                @signatures.each do |method, type|
                  # Also add a constant pointing to the signature type inside Signatures (and substitute ! for Bang, as that's not allowed in a constant)
                  # This helps with debugging, as we won't get anonymous struct classes, but we'll see these better names
                  cleaned_name = method.to_s.gsub(/!/, '_bang')
                  self::MethodSignatures.const_set(cleaned_name.camelize.to_sym, type)
                  coerce_params_for method, type
                end
              end

              super
            end

            def signature(method, &block)
              @signatures ||= {}
              if block_given?
                type =
                  Class.new(Attributor::Struct) do
                    attributes do
                      # attribute :body, String, null: false, values: ['asdfa']
                      instance_eval(&block)
                    end
                  end
                @signatures[method] = type
              else
                @signatures[method]
              end
            end

            # Sets up a specific around callback to a given method, where it'd pass the loaded/coerced type from the input
            def coerce_params_for(method, type)
              raise "Argument type for #{method} could not be found. Did you define a `signature` stanza for it?" unless type

              if method_defined?(method)
                coerce_params_for_instance(instance_method(method), type)
              elsif methods.include?(method)
                coerce_params_for_class(method(method), type)
              else
                raise "Method #{method} not defined in #{name}. Make sure you define the coercion stanza after the methods have been defined"
              end
            end

            def coerce_params_for_instance(method, type)
              around_method_name = "_coerce_params_for_#{method.name}"
              ctx = [to_s, method.name].freeze
              define_method(around_method_name) do |*args, &block|
                loaded = type.load(*args,ctx)
                errors = type.validate(loaded, ctx, nil)
                # TODO: Throw a specific exception...
                raise IncompatibleTypeForMethodArguments.new(errors: errors, method: method.name, klass: self) unless errors.empty?

                block.yield(loaded)
              end

              # Set an around callback to call the defined method above
              around method.name, around_method_name
            end

            def coerce_params_for_class(method, type)
              around_method_name = "_coerce_params_for_class_#{method.name}"
              singleton_class.instance_eval do # Define an instance method in the eigenclass
                ctx = [to_s, method.name].freeze
                define_method(around_method_name) do |*args, &block|
                  loaded = type.load(*args,ctx)
                  errors = type.validate(loaded, ctx, nil)
                  # TODO: Throw a specific exception...
                  raise IncompatibleTypeForMethodArguments.new(errors: errors, method: method.name, klass: self) unless errors.empty?

                  block.yield(loaded)
                end
              end

              # Set an around callback to call the defined method above
              around method.name, around_method_name
            end
          end
        end
      end
    end
  end
end