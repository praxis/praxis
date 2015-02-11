module Praxis
  class ApiGeneralInfo
        
    def name(val=nil)
      return @name unless val
      @name = val
    end

    def title(val=nil)
      return @title unless val
      @title = val
    end

    def description(val=nil)
      return @description unless val
      @description = val
    end

    def base_path(val=nil)
      return @base_path unless val
      @base_path = val
    end
        
    def describe
      hash = { schema_version: "1.0".freeze }

      [:name, :title, :description, :base_path].each do |attr|
        val = self.__send__(attr) 
        hash[attr] = val unless val.nil?
      end
      hash
    end      
        
  end
  
end