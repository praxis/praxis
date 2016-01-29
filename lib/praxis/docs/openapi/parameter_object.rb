require_relative 'schema_object'

module Praxis
  module Docs
    module OpenApi
      class ParameterObject
        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#parameter-object
        attr_reader :location, :name, :is_required, :info
        def initialize(location: , name:, is_required:,  info:)
          @location = location
          @name = name
          @info = info
          @is_required = is_required
        end

        def dump
          # Fixed fields
          h = { name: name, in: location }
          h[:description] = info.options[:description] if info.options[:description]
          h[:required] = is_required if is_required
          # h[:deprecated] = false
          # h[:allowEmptyValue] ??? TODO: support in Praxis

          # Other supported attributes
          # style
          # explode
          # allowReserved
          
          # Now merge the rest schema and example
          # schema
          # example
          # examples (Example and Examples are mutually exclusive)
          schema = SchemaObject.new(info: info)
          h[:schema] = schema.dump_schema
          # Note: we do not support the 'content' key...we always use schema
          h[:example] = schema.dump_example
          h
        end

        def self.process_parameters( action )
          output = []
          # An array, with one hash per param inside  
          if action.headers
            (action.headers.attributes||{}).each_with_object(output) do |(name, info), out|
              out << ParameterObject.new( location: 'header', name: name, is_required: info.options[:required], info: info ).dump
            end
          end
  
          if action.params
            route_params = \
              if action.primary_route.nil?
                warn "Warning: No routes defined for action #{action.name}"
                []
              else
                action.primary_route.path.named_captures.keys.collect(&:to_sym)
              end
            (action.params.attributes||{}).each_with_object(output) do |(name, info), out|
              in_type = route_params.include?(name) ? :path : :query
              is_required = (in_type == :path ) ? true : info.options[:required]
              out << ParameterObject.new( location: in_type, name: name, is_required: is_required, info: info ).dump
            end
          end

          output
        end
      end
    end
  end
end
