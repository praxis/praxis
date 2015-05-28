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

    def id
      self.class.name.gsub("::",'-')
    end

    def describe(shallow=true)
      {identifier: identifier}
    end

  end

end
