# frozen_string_literal: true

class VolumeSnapshot < Praxis::MediaType
  identifier 'application/json'

  attributes do
    attribute :id, Integer
    attribute :name, String, regexp: /snapshot-(\w+)/
  end

  default_fieldset do
    attribute :id
    attribute :name
  end

  class CollectionSummary < Praxis::MediaType
    identifier 'application/json'

    attributes do
      attribute :name, String, regexp: /snapshots-(\w+)/
      attribute :size, Integer
      attribute :href, String
    end

    default_fieldset do
      attribute :name
      attribute :size
      attribute :href
    end
  end
end
