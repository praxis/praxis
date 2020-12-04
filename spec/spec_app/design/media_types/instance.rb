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

  default_fieldset do
    attribute :id
    attribute :root_volume
  end
end
