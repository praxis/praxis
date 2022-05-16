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
                  # For class Methods, also substitute .self for Self
                  # This helps with debugging, as we won't get anonymous struct classes, but we'll see these better names
                  cleaned_name = method.to_s.gsub(/!/, '_bang').to_s.gsub(/^self./, 'self_')
                  self::MethodSignatures.const_set(cleaned_name.camelize.to_sym, type)
                  coerce_params_for method, type
                end
              end

              super
            end

            def signature(method_name, &block)
              method = method_name.to_sym
              @signatures ||= {}
              if block_given?
                type =
                  Class.new(Attributor::Struct) do
                    attributes do
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

              if method.start_with?('self.')
                simple_name = method.to_s.gsub(/^self./, '').to_sym
                # Look for a Class method
                raise "Error building typed method signature: Method #{method} is not defined in class #{name}" unless methods.include?(simple_name)

                coerce_params_for_class(method(simple_name), type)
              else
                # Look for an instance method
                raise "Error building typed method signature: Method #{method} is not defined in class #{name}" unless method_defined?(method)

                coerce_params_for_instance(instance_method(method), type)
              end
            end

            def coerce_params_for_instance(method, type)
              around_method_name = "_coerce_params_for_#{method.name}"
              instance_exec around_method_name: around_method_name,
                            orig_method: method,
                            type: type,
                            ctx: [to_s, method.name].freeze,
                            &CREATE_LOADER_METHOD

              # Set an around callback to call the defined method above
              around method.name, around_method_name
            end

            def coerce_params_for_class(method, type)
              around_method_name = "_coerce_params_for_class_#{method.name}"
              # Define an instance method in the eigenclass
              singleton_class.instance_exec around_method_name: around_method_name,
                                            orig_method: method,
                                            type: type,
                                            ctx: [to_s, method.name].freeze,
                                            &CREATE_LOADER_METHOD

              # Set an around callback to call the defined method above (the callbacks need self. for class interceptors)
              class_method_name = "self.#{method.name}"
              around class_method_name.to_sym, around_method_name
            end

            CREATE_LOADER_METHOD = proc do |around_method_name:, orig_method:, type:, ctx:|
              has_args = orig_method.parameters.any? { |(argtype, _)| %i[req opt rest].include?(argtype) }
              has_kwargs = orig_method.parameters.any? { |(argtype, _)| %i[keyreq keyrest].include?(argtype) }
              raise "Typed signatures aren't supported for methods that have both kwargs and normal args: #{orig_method.name} of #{self.class}" if has_args && has_kwargs
              if has_args
                define_method(around_method_name) do |arg, &block|
                  loaded = type.load(arg, ctx)
                  errors = type.validate(loaded, ctx, nil)
                  raise IncompatibleTypeForMethodArguments.new(errors: errors, method: orig_method.name, klass: self) unless errors.empty?

                  # pass the struct object as a single arg
                  block.yield(loaded)
                end
              else
                define_method(around_method_name) do |**args, &block|
                  loaded = type.load(args, ctx)
                  errors = type.validate(loaded, ctx, nil)
                  raise IncompatibleTypeForMethodArguments.new(errors: errors, method: orig_method.name, klass: self) unless errors.empty?
  
                  # Splat the args if it's a kwarg type method
                  block.yield(**loaded)
                end
              end
            end
          end
        end
      end
    end
  end
end
