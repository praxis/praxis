module Praxis
  module Extensions

    module Rendering
      extend ActiveSupport::Concern
      include FieldExpansion

      def render(object, include_nil: false)
        loaded = self.media_type.load(object)
        renderer = Praxis::Renderer.new(include_nil: include_nil)
        renderer.render(loaded, self.expanded_fields)

      rescue Attributor::DumpError => e
        if self.media_type.domain_model == Object
          warn "Detected the rendering of an object of type #{self.media_type} without having a domain object model set.\n" +
               "Did you forget to define it?"
        end
        raise
      end

      def self.default_encoder
        ''
      end

      def display(object, include_nil: false, encoder: self.default_encoder )
        identifier = Praxis::MediaTypeIdentifier.load(self.media_type.identifier)
        response.headers['Content-Type'] = (identifier + encoder).to_s
        response.body = render(object, include_nil: include_nil)
        response
      end
    end
  end
end
