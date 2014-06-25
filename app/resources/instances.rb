module ApiResources
  class Instances
    include Praxis::ResourceDefinition

    media_type 'application/json'
    version '1.0'

    #response_groups :premium
    #responses :instance_limit_reached
    #responses :pay_us_money
    
    use :authenticated

    routing do
      prefix '/clouds/:cloud_id/instances'
    end

    params do
      attribute :cloud_id, Integer, required: true
    end

    action :index do
      routing do
        get ''
      end
    end

    action :show do
      routing do
        get '/:id'
      end

      responses :other_response

      params do
        attribute :id, Integer, required: true, min: 1
        attribute :junk, String, default: ''
        attribute :some_date, DateTime, default: DateTime.parse('2012-12-21')
      end
      payload do
        attribute :something, String
        attribute :optional, String, default: "not given"
      end
    end

  end
end
