require_relative 'base'

module Resources
  class Forwarderer
    extend Forwardable
    attr_accessor :target

    def self.for(names)
      Class.new(self) do
        
        names.map(&:to_sym).each do |spec|
          if spec.is_a? Symbol
            def_delegator :@target, spec
          else
            name = spec.keys.first
            def_delegator :@target, name, spec[name]
          end
        end
      end  
    end
    def initialize(target)
      @target = target
    end

    def foo
      target.name
    end
  end

  class Book < Resources::Base
    model ::ActiveBook

    filters_mapping(
      name: :simple_name
    )

    order_mapping(
      name: 'simple_name',
      writer: 'author'
    )

    property :name, dependencies: [:simple_name]
    def name
      record.simple_name
    end

    property :grouped, dependencies: [:simple_name, :category_uuid] # TODO: Dependency resolution should have kicked in when asking for 'grouped' without any inner ones...
    def grouped
      @_grouped_fwd ||= Forwarderer.for([:id, :name])
      @_grouped_fwd.new(self) # This shouldn't be a 'new' ... but a class new...
    end
  end
end
