module ApiResources
  class Volumes
    include Praxis::ResourceDefinition

    media_type Volume
    version '1.0', using: :path

    prefix '/volumes'

    trait :authenticated
    
    action :index do
      routing do
        get ''
      end
      response :ok
      response :unauthorized
    end

    action :show do
      routing do
        get '/:id'
      end

      response :ok
      response :unauthorized

      params do
        attribute :id
        attribute :junk, String, default: ''
        attribute :some_date, DateTime, default: DateTime.parse('2012-12-21')
      end
      
    end

  end

end
