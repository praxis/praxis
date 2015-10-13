class Person < Praxis::MediaType
  identifier "application/vnd.acme.person"

  attributes do
    attribute :id, Integer
    attribute :name, String, example: /[:name:]/
    attribute :href, String, example: proc { |person| "/people/#{person.id}" }
    attribute :links, silence_warnings { Praxis::Collection.of(String) }
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

  class CollectionSummary < Praxis::MediaType
    attributes do
      attribute :href, String
      attribute :size, Integer
    end

    view :link do
      attribute :href
      attribute :size
    end

  end
end


class Address < Praxis::MediaType
  identifier 'application/json'

  description 'Address MediaType'
  display_name 'The Address'

  attributes do
    attribute :id, Integer
    attribute :name, String

    attribute :owner, Person
    attribute :custodian, Person

    attribute :residents, Praxis::Collection.of(Person)
    attribute :residents_summary, Person::CollectionSummary

    links do
      link :owner
      link :super, Person, using: :manager
      link :caretaker, using: :custodian
      link :residents, using: :residents_summary
    end

  end

  view :default do
    attribute :id
    attribute :name
    attribute :owner

    attribute :links
  end
end
