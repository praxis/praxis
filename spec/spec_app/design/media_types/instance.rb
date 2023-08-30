# frozen_string_literal: true

class Instance < Praxis::MediaType
  identifier 'application/vnd.acme.instance'

  attributes do
    attribute :id, Integer
    attribute :name, String,
              example: proc { Faker::Name.first_name },
              regexp: /^\w+$/

    attribute :href, String

    attribute :root_volume, Volume, null: true

    attribute :volumes, Volume::Collection
  end

  default_fieldset do
    attribute :id
    attribute :root_volume
  end
end
