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


  class Collection < Praxis::MediaTypeCollection
    identifier 'application/json+collection'

    member_type VolumeSnapshot

    attributes do
      attribute :name, String, regexp: /snapshots-(\w+)/
      attribute :size, Integer, example: proc { |collection| collection.to_a.count }
      attribute :href, String
    end

    view :link do
      attribute :name
      attribute :size
      attribute :href
    end

    member_view :default, using: :default
  end

end
