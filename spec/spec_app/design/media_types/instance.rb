class Instance < Praxis::MediaType

  identifier 'application/vnd.acme.instance'

  attributes do
    attribute :id, Integer
    attribute :name, String, 
      example: /[:first_name:]/,
      regexp: /^\w+$/

    attribute :href, String

    attribute :root_volume, Volume

    attribute :volumes, Volume::Collection
    
  end

  view :default do
    attribute :id
    attribute :root_volume
  end

  view :link do
    attribute :id
    attribute :href
  end

  view :create do
    attribute :id
    attribute :name
  end

  view :extended, include_nil: true do
    attribute :id
    attribute :name
    attribute :root_volume
  end


end
