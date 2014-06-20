module ApiResources
  class Instances  #< Praxis::Skeletor::RestfulSinatraApplicationConfig
    include Praxis::ResourceDefinition

    media_type 'application/json'
    version '1.0'
    
    action :index do
      routing do 
        get ''
      end
    end

    action :show do
      routing do
        get '/:id'
      end
      #headers do
      #  header :version
      #end
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
