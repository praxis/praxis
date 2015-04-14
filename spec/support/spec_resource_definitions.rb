require_relative 'spec_media_types'

Praxis::ApiDefinition.define do
  trait :test do
    description 'testing trait'
  end
end

class PeopleResource
  include Praxis::ResourceDefinition

  description 'People resource'

  media_type Person

  version '1.0'

  canonical_path :show

  trait :test

  prefix '/people'

  action :index do
    description 'index description'
    routing do
      get ''
    end
  end

  action :show do
    description 'show description'
    routing do
      get '/:id'
    end
    params do
      attribute :id, Integer, required: true
    end
  end

end


class AddressResource
  include Praxis::ResourceDefinition

  description 'Address resource'

  media_type Address

  version '1.0'

  prefix '/addresses'

  action :index do
    description 'index description'
    routing do
      get ''
    end
  end

  action :show do
    description 'show description'
    routing do
      get '/:id'
    end
    params do
      attribute :id, Integer, required: true
    end
  end

end
