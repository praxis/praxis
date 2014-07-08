require_relative 'spec_media_types'

class PeopleResource
  include Praxis::ResourceDefinition

  description 'People resource'

  media_type Person

  version '1.0'

  routing do
    prefix "/people"
  end

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
