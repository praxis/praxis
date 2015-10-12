module Praxis
 class Collection < Attributor::Collection
    include Types::MediaTypeCommon

    def self.of(type)
      if defined?(type::Collection)
        return type::Collection
      end

      klass = super

      if type < Praxis::Types::MediaTypeCommon
        klass.member_type type
        type.const_set :Collection, klass
      else
        warn "DEPRECATION: Praxis::Collection.of() for non-MediaTypes will be unsupported in 1.0. Use Attributor::Collection.of() instead."
        Attributor::Collection.of(type)
      end

    end

    def self.member_type(type=nil)
      unless type.nil?
        @member_type = type
        self.identifier(type.identifier + ';type=collection') unless type.identifier.nil?
      end

      @member_type
    end

  end
end
