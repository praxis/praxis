module Praxis
  module Docs
    # Generates links into the generated doc browser.
    class LinkBuilder
      include Singleton

      # Generates a link based on a request gone wrong.
      # @return [String, nil] The doc browser link.
      def linkForRequest(req)
        build_link req.version, 'controller', req.action.resource_definition.id, req.action.name
      end

      private

      def build_link(*segments)
        if endpoint
          endpoint + '#' + segments.join('/')
        end
      end

      def endpoint
        @endpoint ||= begin
          endpoint = ApiDefinition.instance.global_info.documentation_url
          endpoint.gsub(/\/index\.html$/i, '/') if endpoint
        end
      end
    end

  end
end
