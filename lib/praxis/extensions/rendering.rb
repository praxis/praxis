# frozen_string_literal: true

module Praxis
  module Extensions
    module Rendering
      extend ActiveSupport::Concern
      include FieldExpansion

      def render(object, include_nil: false)
        loaded = media_type.load(object)
        renderer = Praxis::Renderer.new(include_nil: include_nil)
        renderer.render(loaded, expanded_fields)
      rescue Attributor::DumpError
        if media_type.domain_model == Object
          warn "Detected the rendering of an object of type #{media_type} without having a domain object model set.\n" \
               'Did you forget to define it?'
        end
        raise
      end

      def display(object, include_nil: false, encoder: default_encoder)
        identifier = Praxis::MediaTypeIdentifier.load(media_type.identifier)
        identifier += encoder unless encoder.blank?
        response.headers['Content-Type'] = identifier.to_s
        response.body = render(object, include_nil: include_nil)
        response
      rescue Praxis::Renderer::CircularRenderingError => e
        Praxis::Application.instance.validation_handler.handle!(
          summary: 'Circular Rendering Error when rendering response. ' \
                   'Please especify a view to narrow the dependent fields, or narrow your field set.',
          exception: e,
          request: request,
          stage: :action,
          errors: nil
        )
      end

      def default_encoder
        ''
      end
    end
  end
end
