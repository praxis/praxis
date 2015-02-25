module Praxis
  
  SimpleMediaType = Struct.new(:identifier) do
    def name
      self.class.name
    end
    
    def id
      self.class.name.gsub("::",'-')
    end

    def ===(other_thing)
      case other_thing
      when String
        identifier == other_thing
      when MediaType
        identifier == other_thing.identifier
      else
        raise 'can not compare'
      end
    end

    def describe(shallow=true)
      {identifier: identifier}
    end
  end

end
