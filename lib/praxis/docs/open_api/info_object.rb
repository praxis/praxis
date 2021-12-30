# frozen_string_literal: true
module Praxis
  module Docs
    module OpenApi
      class InfoObject
        attr_reader :info, :version

        def initialize(version:, api_definition_info:)
          @version = version
          @info = api_definition_info
          raise "OpenApi docs require a 'Title' for your API." unless info.title
        end

        def dump
          data = { version: version }
          %i[
            title
            description
            termsOfService
            contact
            license
          ].each do |attr|
            val = info.send(attr)
            data[attr] = val if val
          end

          # Special attributes
          data[:'x-name'] = info.name
          if info.logo_url
            data[:'x-logo'] = {
              url: info.logo_url,
              backgroundColor: '#FFFFFF',
              altText: info.title
            }
          end
          data
        end
      end
    end
  end
end
