class VolumeSnapshot < Praxis::MediaType
  identifier 'application/json'

  attributes do
    attribute :id, Integer
    attribute :name, String, regexp: /snapshot-(\w+)/
  end

  view :default do
    attribute :id
    attribute :name
  end

  view :link do
    attribute :id
  end


  class CollectionSummary < Praxis::MediaType
    identifier 'application/json'

    attributes do
      attribute :name, String, regexp: /snapshots-(\w+)/
      attribute :size, Integer
      attribute :href, String
    end

    view :default do
      attribute :name
      attribute :size
      attribute :href
    end

    view :link do
      attribute :name
      attribute :size
      attribute :href
    end

  end

end
