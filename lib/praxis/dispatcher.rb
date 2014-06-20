module Praxis

  CONTEXT_FOR = {
    params: [Attributor::AttributeResolver::ROOT_PREFIX, "params".freeze],
    headers: [Attributor::AttributeResolver::ROOT_PREFIX, "headers".freeze],
    payload: [Attributor::AttributeResolver::ROOT_PREFIX, "payload".freeze]
  }.freeze

  class Dispatcher


    class << self

      def setup_request(action, request)
        request.coalesce_inputs!

        request.load_headers(CONTEXT_FOR[:headers])
        request.load_params(CONTEXT_FOR[:params])

        attribute_resolver = Attributor::AttributeResolver.new
        Attributor::AttributeResolver.current = attribute_resolver

        attribute_resolver.register("headers",request.headers)
        attribute_resolver.register("params",request.params)

        request.validate_headers(CONTEXT_FOR[:headers])
        request.validate_params(CONTEXT_FOR[:params])

        # TODO: handle multipart requests
        if action.payload
          request.load_payload(CONTEXT_FOR[:payload])
          attribute_resolver.register("payload",request.payload)
          request.validate_payload(CONTEXT_FOR[:payload])
        end
      end


      def dispatch(controller, action, request)
        setup_request(action, request)

        controller_instance = controller.new(request)
        response = controller_instance.send(action.name, **request.params_hash)

        if response.kind_of? String
          controller_instance.response.body = response
        else
          controller_instance.response = response
        end

        response = controller_instance.response
        response.request = request

        response.handle
        response.validate(action)

        response.to_rack
      end


    end
  end
end







