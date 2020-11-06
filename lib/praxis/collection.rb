module Praxis
  class Collection < Attributor::Collection
    include Types::MediaTypeCommon

    def self.of(type)
      if defined?(type::Collection)
        return type::Collection
      end

      klass = super
      klass.anonymous_type

      if type < Praxis::Types::MediaTypeCommon
        klass.member_type type
        type.const_set :Collection, klass
      else
        raise "Praxis::Collection.of() for non-MediaTypes is unsupported. Use Attributor::Collection.of() instead."
      end

    end

    def self.member_type(type=nil)
      unless type.nil?
        @member_type = type
        @views = nil
        self.identifier(type.identifier + ';type=collection') unless type.identifier.nil?
      end

      @member_type
    end

    def self.views
      @views ||= begin
        @member_type.views.each_with_object(Hash.new) do |(name, view), hash|
          hash[name] = Praxis::CollectionView.new(name, @member_type, view)
        end
      end
    end

    def self.domain_model
      @member_type.domain_model
    end

  end
end
