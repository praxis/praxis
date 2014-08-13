module Praxis

  class ResponseTemplate
    attr_reader :name, :block

    def initialize(response_name, &block)
      @name = response_name
      @block = block
    end

    def compile(action=nil, **args)
      # Default media_type to the resource_definition one, if the block has it in
      # its required args but no value is passed (funky, but can help in the common case)
      if block.parameters.any? { |(type, name)| name == :media_type && type == :keyreq } && action
        unless args.has_key? :media_type
          media_type = action.resource_definition.media_type
          unless media_type
            raise Exceptions::InvalidConfigurationException.new(
              "Could not default :media_type argument for response template #{@name}." +
               " Resource #{action.resource_definition} does not have an associated mediatype and none was passed"
            )
          end
          args[:media_type] = media_type
        end
      end
      Praxis::ResponseDefinition.new(name, **args, &block)   
    end

    def describe
      puts "TODO!!!!!!"
    end
  end

end
