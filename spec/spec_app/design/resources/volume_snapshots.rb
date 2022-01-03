# frozen_string_literal: true

require_relative 'volumes'

module ApiResources
  class VolumeSnapshots
    include Praxis::EndpointDefinition

    media_type VolumeSnapshot

    version '1.0'

    parent Volumes, id: :volume_id
    prefix '/snapshots'

    action :index do
      routing do
        get ''
      end
      response :ok
      response :unauthorized

      params do
        attribute :volume_id, Integer, description: 'id of parent volume'
      end
    end

    action :show do
      routing do
        get '/:id'
      end

      params do
        attribute :id
      end
    end
  end
end
