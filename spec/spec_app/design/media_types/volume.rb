# frozen_string_literal: true

class Volume < Praxis::MediaType
  identifier 'application/vnd.acme.volume'

  attributes do
    attribute :id, Integer
    attribute :name, String

    attribute :source, VolumeSnapshot

    attribute :snapshots, Praxis::Collection.of(VolumeSnapshot)
    attribute :snapshots_summary, VolumeSnapshot::CollectionSummary
  end

  default_fieldset do
    attribute :id
    attribute :name
    attribute :source
    attribute :snapshots
  end

  class Collection < Praxis::Collection
    member_type Volume

    identifier 'application/vnd.acme.volumes'
  end
end
