module Resources
  class Base < Praxis::Mapper::Resource
    include Praxis::Mapper::Resources::QueryMethods # So we can directly get wrapped models with get, all, first, last...

    # def self.inherited(klass)
    #   # Add the code that allows to define typed method signatures (to be validated and coerced) to the concrete class
    #   klass.include Praxis::Mapper::Resources::TypedMethods
    # end
  end
end

