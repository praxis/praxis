require 'singleton'
require 'forwardable'

module Praxis

  class ApiDefinition
    include Singleton
    extend Forwardable

    attr_reader :traits

    def self.define
      yield(self.instance)
    end

    def initialize
      @responses = Hash.new
      @traits = Hash.new
    end

    def register_response(name, group: :default, &block)
      @responses[name] = Praxis::ResponseTemplate.new(name,group:group, &block)
    end

    def response(name)
      return @responses.fetch(name) do
        raise ArgumentError, "no response defined with name #{name.inspect}"
      end
    end


    def responses(names: [], groups: [])
      set = Set.new

      groups.each do |group_name|
        group = @responses.values.select { |response| response.group == group_name }
        if group.empty?
          raise ArgumentError, "no responses defined with group name #{group_name.inspect}"
        end
        set.merge group
      end

      names.each do |name|
        set << response(name)
      end

      set
    end

    def trait(name, &block)
      raise "Umm...overwriting a previous trait with the same name" if self.traits.has_key? name
      self.traits[name] = block
    end


    define do |api|
      api.register_response :default do |media_type: :controller_defined|
        media_type media_type
        status 200
      end

      api.register_response :not_found do
        status 404
      end

      api.register_response :validation do
        description "When parameter validation hits..."
        status 400
        media_type "application/json"
      end

      api.register_response :internal_server_error do
        description "Internal Server Error"
        status 500
      end
    end

  end

end
