class Volume < Praxis::MediaType
  identifier 'application/json'

  attributes do
    attribute :id, Integer
    attribute :name, String

    attribute :source, VolumeSnapshot

    # returns VolumeSnapshot::Collection if exists
    attribute :snapshots, Praxis::Collection.of(VolumeSnapshot)

    links do
      link :source
      link :snapshots
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

end


