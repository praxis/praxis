module Praxis
  module Types
    class MultipartArray < Attributor::Collection
      class PartDefinition
        attr_accessor :payload_attribute, :headers_attribute, :filename_attribute

        def initialize(&block)
          instance_eval(&block)
        end

        def update_attribute(attribute, options, block)
          attribute.options.merge!(options)
          attribute.type.attributes(**options, &block)
        end

        def create_attribute(type = Attributor::Struct, **opts, &block)
          # TODO: how do we want to handle any referenced types?
          Attributor::Attribute.new(type, opts, &block)
        end

        def payload(type = Attributor::Struct, **opts, &block)
          # return @payload if !block_given? && type == Attributor::Struct
          @payload_attribute = create_attribute(type, **opts, &block)
        end

        def header(name, val = nil, **options)
          block = proc { header(name, val, **options) }

          if @headers_attribute
            update_attribute(@headers_attribute, options, block)
          else
            type = Attributor::Hash.of(key: String)
            @headers_attribute = create_attribute(type,
                                                  dsl_compiler: Praxis::ActionDefinition::HeadersDSLCompiler,
                                                  case_insensitive_load: false, # :(
                                                  allow_extra: true,
                                                  &block)
          end
        end

        def filename(type = String, **opts)
          @filename_attribute = create_attribute(type, **opts)
        end
      end
    end
  end
end
