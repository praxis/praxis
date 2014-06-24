# A RESTful action allows you to define the following:
# - a payload structure
# - a params structure
# - the response MIME type
# - the return code/s ?
#
# Plugins may be used to extend this Config DSL.
#
module Praxis
  module Skeletor

    class RestfulActionConfig

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
          raise "You cannot use the 'attribute' DSL inside a headers definition" #if (type.nil? || !type==String)
        end

      end

      attr_accessor :name, :controller_config, :routing_config #mime_type, media_type  #params, payload

      def initialize(name, controller_config, opts={}, &block)
        # TODO: I think we can get away without a name...and just storing the configuration (RestfulSinatraApplicationConfig.action already keys this config off of the action name)
        @name = name
        @responses=Set.new
        @response_groups = Set.new
        @controller_config = controller_config
        unless (media_type = opts.delete(:media_type)).kind_of?(SimpleMediaType)
          @reference_media_type = media_type
        end
        #TODO: I don't know that we need to get "options" passed in...any option should be basically expressed in the allowed DSL...
        raise "Unsupported option/s (#{opts.join(',')}) for defining actions found in action #{name}" if opts.size > 0


        if controller_config.params_config
          saved_type, saved_opts, saved_block = controller_config.params_config
          @params = create_attribute(saved_type, saved_opts, &saved_block)
        end

        if controller_config.payload_config
          saved_type, saved_opts, saved_block = controller_config.payload_config
          @payload = create_attribute(saved_type, saved_opts, &saved_block)
        end

        if controller_config.headers_config
          saved_type, saved_opts, saved_block = controller_config.headers_config
          @headers = create_attribute(saved_opts, &saved_block)
        end

        self.instance_eval(&block) if block_given?


      end


      def responses(*responses)
        @responses.merge(responses)
      end

      def response_groups(*response_groups)
        @response_groups.merge(response_groups)
      end



      def create_attribute(type=Attributor::Struct, **opts, &block)
        unless opts[:reference]
          opts[:reference] = @reference_media_type if @reference_media_type && block
        end

        return Attributor::Attribute.new(type, opts, &block)
      end

      def update_attribute(attribute, options, block)
        attribute.options.merge!(options)
        attribute.type.attributes(options, &block)
      end

      def use(trait_name)
        self.instance_eval(&Skeletor.traits[trait_name])
      end

      def params(type=Attributor::Struct, **opts, &block)
        return @params if !block && type == Attributor::Struct

        if @params
          unless type == Attributor::Struct && @params.type < Attributor::Struct
            raise 'type mismatch'
          end
          update_attribute(@params, opts, block)
        else
          @params = create_attribute(type, **opts, &block)
        end
      end

      def payload(type=Attributor::Struct, **opts, &block)
        return @payload if !block && type == Attributor::Struct

        if @payload
          unless type == Attributor::Struct && @payload.type < Attributor::Struct
            raise 'type mismatch'
          end
          update_attribute(@payload, opts, block)
        else
          @payload = create_attribute(type, **opts, &block)
        end
      end


      def headers(**opts, &block)
        return @headers unless block

        if @headers
          update_attribute(@headers, opts, block)
        else
          @headers = create_attribute(dsl_compiler: HeadersDSLCompiler, **opts, &block)
        end
      end

      def routing(&block)
        @routing_config = RestfulRoutingConfig.new(name, controller_config, &block)
      end

      def description(text = nil)
        @description = text if text
        @description
      end

      def describe
        {}.tap do |hash|
          hash[:description] = description
          hash[:name] = name
          hash[:urls] = urls
          hash[:headers] = headers.describe if headers
          hash[:params] = params.describe if params
          hash[:payload] = payload.describe if payload
          hash[:responses] = all_responses.inject({}) do |memo, kv|
            memo[kv[0]] = kv[1].describe
            memo
          end
        end
      end

    end
  end
end
