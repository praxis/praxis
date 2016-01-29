module Praxis
  module Docs
    module OpenApi
      class InfoObject
        attr_reader :info, :version
        def initialize(version: , api_definition_info: )
          @version = version
          @info = api_definition_info
          raise "OpenApi docs require a 'Title' for your API." unless info.title
        end

        def dump
          data ={
            title: info.title,
            description: info.description,
            termsOfService: info.termsOfService,
            contact: info.contact,
            license: info.license,
            version: version,
            :'x-name' => info.name,
            :'x-logo' => {
              url: info.logo_url,
              backgroundColor: "#FFFFFF",
              altText: info.title
            }
          }
        end
      end
    end
  end
end
