# frozen_string_literal: true

module Praxis
  # Stripped-down representation of an Internet Media Type where the structure and content of the
  # type are unknown, or are defined externally to the Praxis application.
  #
  # @see Praxis::MediaType
  # @see Praxis::Types::MediaTypeCommon
  SimpleMediaType = Struct.new(:identifier) do
    def name
      self.class.name
    end

    def self.id
      'Praxis-SimpleMediaType'
    end

    def id
      self.class.id
    end

    def describe(*)
      { name: name, family: 'string', id: id, identifier: identifier }
    end
  end
end
