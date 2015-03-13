module Praxis
 class Collection < Attributor::Collection
    include Types::MediaTypeCommon

    def self.of(type)
      if defined?(type::Collection)
        return type::Collection
      end

      klass = super

      if type < Praxis::Types::MediaTypeCommon
        unless type.identifier.nil?
          klass.identifier(type.identifier + ';type=collection')
        end

        type.const_set :Collection, klass
      else
        warn "DEPRECATION: Praxis::Collection.of() for non-MediaTypes will be unsupported in 1.0. Use Attributor::Collection.of() instead."
        Attributor::Collection.of(type)
      end

    end

    def self.member_type(type=nil)
      unless type.nil?
        @member_type = type
      end

      @member_type
    end

  end
end
