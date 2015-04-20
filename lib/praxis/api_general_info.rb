module Praxis
  class ApiGeneralInfo

    def initialize(global_info=nil)
      @global_info = global_info
      @data = Hash.new
    end

    def get(k)
      return @data[k] if @data.key?(k)
      return @global_info.get(k) if @global_info
      nil
    end

    def set(k, v)
      @data[k] = v
    end

    def name(val=nil)
      if val.nil?
        get(:name)
      else
        set(:name, val)
      end
    end

    def title(val=nil)
      if val.nil?
        get(:title)
      else
        set(:title, val)
      end
    end

    def description(val=nil)
      if val.nil?
        get(:description)
      else
        set(:description, val)
      end
    end

    def base_path(val=nil)
      if val
        return set(:base_path, val)
      end

      if @global_info
        version_path = @data.fetch(:base_path,'')
        global_path = @global_info.get(:base_path)
        "#{global_path}#{version_path}"
      else
        @data.fetch(:base_path,'')
      end
    end

    def base_params(type=Attributor::Struct, **opts, &block)
      if !block && type == Attributor::Struct
        get(:base_params)
      else
        set(:base_params, Attributor::Attribute.new(type, opts, &block) )
      end
    end

    def describe
      hash = { schema_version: "1.0".freeze }
      [:name, :title, :description, :base_path].each do |attr|
        val = self.__send__(attr)
        hash[attr] = val unless val.nil?
      end
      if base_params
        hash[:base_params] = base_params.describe[:type][:attributes]
      end
      hash
    end

  end

end
