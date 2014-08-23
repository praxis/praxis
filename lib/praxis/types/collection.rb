module Praxis

  class Collection

    # checks if +type+ is a MediaType, and if so, if it has an inner
    # Collection class defined
    def self.of(type)
      if type < Attributor::Type && defined?(type::Collection)
        return type::Collection
      end

      Attributor::Collection.of(type)
    end

  end

end
