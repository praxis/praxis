class Person < Praxis::MediaType
  attributes do 
    attribute :id, Integer
    attribute :name, String, example: /[:name:]/
    attribute :href, String, example: proc { |person| "/people/#{person.id}" }
    attribute :links, Praxis::Collection.of(String)
  end

  view :default do
    attribute :id
    attribute :name
    attribute :links
  end

  view :link do
    attribute :id
    attribute :name
    attribute :href
  end
end


class Address < Praxis::MediaType
  identifier 'application/json'

  description 'Address MediaType'

  attributes do
    attribute :id, Integer
    attribute :name, String

    attribute :owner, Person

    links do
      link :owner
      link :super, Person, using: :manager
    end

  end

  view :default do
    attribute :id
    attribute :name
    attribute :owner

    attribute :links
  end
end
