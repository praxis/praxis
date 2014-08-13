module Praxis
  class ActionDefinition
    class HeadersDSLCompiler < Attributor::DSLCompiler

      alias_method :orig_attribute, :attribute
      # it allows to define expectations on incoming headers. For example:
      # header :X_SpecialCookie                        => implies the header is required
      # header :X_Something, /matching_this/           => implies that if the name header exists, it should match the regexp
      # header :X_A_Header, "Specific String"          => implies that the value matches the string exactly
      # In any of the cases, other supported options might be passed
      # header :X_Something, /matching_this/ ,
      #                     required: true             => to make it required
      #                     description: "lorem ipsum" => to describe it (like any other attribute)

      def header(name, val=nil, **options )
        case val
        when Regexp
          options[:regexp] = val
        when String
          options[:values] = [val]
        when nil
          # Defining the existence without any other options can only mean that it is required (otherwise it is a useless definition)
          options[:required] = true if options.empty?
        end
        orig_attribute name.upcase , String, options
      end

      def attribute( name, type, **rest)
        raise Exceptions::InvalidConfigurationException.new(
          "You cannot use the 'attribute' DSL inside a headers definition" #if (type.nil? || !type==String)
        )
      end

    end
  end
end
