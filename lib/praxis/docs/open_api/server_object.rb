# frozen_string_literal: true

module Praxis
  module Docs
    module OpenApi
      class ServerObject
        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#server-object
        attr_reader :url, :description, :variables

        def initialize(url:, description: nil, variables: [])
          @url = url
          @description = description
          @variables = variables
          raise "OpenApi docs require a 'url' for your server object." unless url
        end

        def dump
          result = { url: url }
          result[:description] = description if description
          result[:variables] = variables unless variables.empty?

          result
        end
      end
    end
  end
end
