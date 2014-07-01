class Volume < Praxis::MediaType

  identifier 'application/json'
  
  attributes do 
    attribute :id, Integer
    attribute :name, String
  end

  view :default do
    attribute :id
    attribute :name
  end

  view :link do
    attribute :id
  end
end