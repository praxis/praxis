module ApiResources
  class Volumes
    include Praxis::EndpointDefinition

    media_type Volume
    version '1.0'
    prefix '/clouds/:cloud_id/volumes'

    trait :authenticated

    action_defaults do
      params do
        attribute :cloud_id, Integer, description: 'id of the cloud'
      end
    end

    action :index do
      routing do
        get ''
      end
      response :ok, media_type: Praxis::Collection.of(Volume)
      response :unauthorized
    end

    action :show do
      routing do
        get '/:id'
      end

      response :ok
      response :unauthorized

      params do
        attribute :id, description: 'ID to find'
        attribute :junk, String, default: ''
        attribute :some_date, DateTime, default: DateTime.parse('2012-12-21')
      end
    end
  end
end
