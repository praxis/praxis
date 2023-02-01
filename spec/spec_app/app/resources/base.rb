module Resources
  class Base < Praxis::Mapper::Resource
    include Praxis::Mapper::Resources::QueryMethods # So we can directly get wrapped models with get, all, first, last...

    def self.inherited(klass)
      klass.include Praxis::Mapper::Resources::Callbacks # So we can use callbacks (after/before/around) within resource code
      # Add the code that allows to define typed method signatures (to be validated and coerced) to the concrete class
      klass.include Praxis::Mapper::Resources::TypedMethods
      super
    end
  end
end

