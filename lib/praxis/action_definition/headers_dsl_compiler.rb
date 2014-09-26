module Praxis
  class ActionDefinition
    class HeadersDSLCompiler < Attributor::DSLCompiler

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
        #orig_attribute name.upcase , String, options
        key name , String, options
      end

      # Override the attribute to really call "key" in the hash (for temporary backwards compat)      
      def attribute(name, attr_type=nil, **opts, &block)
        warn "[DEPRECATION] `attribute` is deprecated when defining headers.  Please use `key` instead."
        key(name, attr_type, **opts, &block)
      end

    end
  end
end
