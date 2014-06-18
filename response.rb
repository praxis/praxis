

class Response

  attr_accessor :name, :status, :headers, :body, :extra_data

  @@responses = []

  def self.inherited(klass)
    @@responses << klass
  end

  def self.response_name=(response_name)
    @response_name = response_name
  end

  def self.response_name
    @response_name
  end

  def self.response_for(response)
    return response if response.response_name == response.name

    klass = @@responses.find { |klass| klass.response_name == response.name }
    if klass.nil? 
      raise "No response defined with name: #{response.name}"
    end

    klass.new(
      status: response.status,
      headers: response.headers,
      body: response.body
    )
  end

  def self.definition
    ApiRoot.response(self.response_name)
  end

  def definition
    self.class.definition
  end

  def response_name
    self.class.response_name
  end

  def initialize(status:200, headers:{}, body:'', **extra_data)
    @name = self.class.response_name
    @status = status
    @headers = headers
    @body = body
    @extra_data = extra_data
  end

  def to_rack
    [@status, @headers, @body]
  end

  def validate(action)
    # Validate status code if defined in the spec
    if definition.status && self.status != definition.status
      raise "Invalid response code detected. Response #{definition.name} dictates status of #{definition.status} but this response is returning #{self.status}."
    end

    # Validate location
    if location = definition.location
      case location
      when Regexp
        raise "LOCATION does not match regexp #{location.inspect}!" unless location =~ self.headers['Location']
      when String
        raise "LOCATION does not match string #{location}!" unless location == self.headers['Location']
      else
        raise "Unknown location spec"
      end
    end

    # Validate headers
    if hdrs = definition.headers
      hdrs = [ hdrs ] if !hdrs.is_a?(Array)

      hdrs.each do |h|
        valid = false

        if h.is_a?(Hash)
          valid = h.all? do |k, v|
            self.headers.has_key?(k) && self.headers[k] == v
          end
        elsif h.is_a?(String)
          valid = self.headers.has_key?(h)
        elsif h.is_a?(Symbol)
          raise "Symbols are not supported"
        end

        raise "headers missing" if !valid
      end
    end

    conf_class = action.controller_config

    extracted_mime = self.headers['Content-Type']
    # Support "+json" and options like ";type=collection"
    extracted_mime = extracted_mime && extracted_mime.split('+').first.split(';').first
    if mt = definition.media_type
      if mt == :controller_defined
        mt = conf_class.media_type
        raise "Error validating content type: this controller (#{conf_class}) doesn't have any associated media_type" unless mt
      end
      raise "Bad Content-Type: returned type #{extracted_mime} does not match type #{mt.mime_type} as described in response: #{definition.name}" unless  extracted_mime == mt.mime_type
    elsif mime = definition.mime_type
      if mime == :controller_defined
        mime = conf_class.mime_type
        raise "Error validating content type: this controller #{conf_class} doesn't have any associated mime_type" unless mime
      end
      raise "Bad mime-type: returned type #{extracted_mime} does not match type #{mime} as described in response: #{definition.name}" unless  mime == extracted_mime
    end
  end

end
