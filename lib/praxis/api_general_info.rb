# frozen_string_literal: true

module Praxis
  class ApiGeneralInfo
    attr_reader :version

    def initialize(global_info = nil, version: nil)
      @data = {}
      @global_info = global_info
      @version = version

      if @global_info.nil? # this *is* the global info
        version_with %i[header params]
        consumes 'json', 'x-www-form-urlencoded'
        produces 'json'
      end
    end

    # Allow any custom method to get/set any value
    def method_missing(name, val = nil)
      if val.nil?
        get(name)
      else
        set(name, val)
      end
    end

    def respond_to_missing?(*)
      true
    end

    def get(k)
      return @data[k] if @data.key?(k)
      return @global_info.get(k) if @global_info

      nil
    end

    def set(k, v)
      @data[k] = v
    end

    def name(val = nil)
      if val.nil?
        get(:name)
      else
        set(:name, val)
      end
    end

    def title(val = nil)
      if val.nil?
        get(:title)
      else
        set(:title, val)
      end
    end

    def logo_url(val = nil)
      if val.nil?
        get(:logo_url)
      else
        set(:logo_url, val)
      end
    end

    def description(val = nil)
      if val.nil?
        get(:description)
      else
        set(:description, val)
      end
    end

    def version_with(val = nil)
      if val.nil?
        get(:version_with)
      elsif @global_info.nil?
        Application.instance.versioning_scheme = val
        set(:version_with, val) # this *is* the global info
      else
        raise 'Use of version_with is only allowed in the global part of ' \
          'the API definition (but you are attempting to use it in the API ' \
          "definition of version #{version}"
      end
    end

    def endpoint(val = nil)
      if val.nil?
        get(:endpoint)
      elsif @global_info.nil?
        set(:endpoint, val) # this *is* the global info
      else
        raise 'Use of endpoint is only allowed in the global part of ' \
          'the API definition (but you are attempting to use it in the API ' \
          "definition of version #{version}"
      end
    end

    def documentation_url(val = nil)
      if val.nil?
        get(:documentation_url)
      elsif @global_info.nil?
        set(:documentation_url, val) # this *is* the global info
      else
        raise 'Use of documentation_url is only allowed in the global part of ' \
          'the API definition (but you are attempting to use it in the API ' \
          "definition of version #{version}"
      end
    end

    def base_path(val = nil)
      return set(:base_path, val) if val

      if @global_info # this is for a specific version
        global_path = @global_info.base_path
        if version_with == :path
          global_pattern = Mustermann.new(global_path)
          global_path = global_pattern.expand(Request::API_VERSION_PARAM_NAME => version.to_s)
        end

        version_path = @data.fetch(:base_path, '')
        "#{global_path}#{version_path}"
      else
        @data.fetch(:base_path, '')
      end
    end

    def consumes(*vals)
      if vals.empty?
        get(:consumes)
      else
        set(:consumes, vals)
      end
    end

    def produces(*vals)
      if vals.empty?
        get(:produces)
      else
        set(:produces, vals)
      end
    end

    def base_params(type = Attributor::Struct, **opts, &block)
      if !block && type == Attributor::Struct
        get(:base_params)
      else
        set(:base_params, Attributor::Attribute.new(type, opts, &block))
      end
    end

    def describe
      hash = { schema_version: '1.0' }
      %i[name title description base_path version_with endpoint consumes produces].each do |attr|
        val = __send__(attr)
        hash[attr] = val unless val.nil?
      end
      hash[:base_params] = base_params.describe[:type][:attributes] if base_params
      hash
    end
  end
end
