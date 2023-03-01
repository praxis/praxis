# frozen_string_literal: true

class Tagging < Praxis::MediaType
  identifier 'application/vnd.acme.tagging'

  domain_model 'Resources::Tagging'
  attributes do
    attribute :tag, Tag
  end
end
