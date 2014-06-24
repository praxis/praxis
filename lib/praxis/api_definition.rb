require 'singleton'

module Praxis

  class ApiDefinition
    include Singleton
    
    def initialize
      @responses = Hash.new
    end

    def response(name, group: :default, &block)
      return @responses[name] unless block_given?

      @responses[name] = Praxis::Skeletor::ResponseDefinition.new(name,group:group, &block)
    end

    def self.response(name, group: :default, &block)
      instance.response(name, group: :default, &block)
    end

    response :default do
      media_type :controller_defined
      status 200
    end

    response :not_found do
      status 404
    end

    response :validation do
      description "When parameter validation hits..."
      status 400
      media_type "application/json"
    end

    response :internal_server_error do
      description "Internal Server Error"
      status 500
    end

  end

end
