module Praxis
  
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
