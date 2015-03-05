class Volume < Praxis::MediaType
  identifier 'application/vnd.acme.volume'

  attributes do
    attribute :id, Integer
    attribute :name, String

    attribute :source, VolumeSnapshot

    attribute :snapshots, Praxis::Collection.of(VolumeSnapshot)
    attribute :snapshots_summary, VolumeSnapshot::CollectionSummary

    links do
      link :source
      link :snapshots, VolumeSnapshot::CollectionSummary, using: :snapshots_summary
    end

  end

  view :default do
    attribute :id
    attribute :name
    attribute :source
    attribute :snapshots
    
    attribute :links
  end

  view :link do
    attribute :id
  end

  class Collection < Praxis::Collection
    @member_type = Volume

    identifier 'application/vnd.acme.volumes'
  end

end


