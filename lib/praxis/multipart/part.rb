module Praxis
  class MultipartPart
    include Attributor::Type

    attr_accessor :body
    attr_accessor :headers
    attr_accessor :filename
    attr_accessor :name
    attr_accessor :payload_attribute
    attr_accessor :headers_attribute
    attr_accessor :filename_attribute
    attr_accessor :default_handler

    def self.check_option!(name, definition)
      case name
      when :payload_attribute, :headers_attribute, :filename_attribute
        unless definition.nil? || definition.kind_of?(Attributor::Attribute)
          raise Attributor::AttributorException.new("Value for option #{name.inspect} must be an Attribute. Got #{definition.class.name}")
        end
      else
        return :unknown
      end

      :ok
    end

    def self.native_type
      self
    end

    def self.json_schema_type
      :object
    end

    def self.example(context=nil, options:{})
      if (payload_attribute = options[:payload_attribute])
        payload = payload_attribute.example(context + ['payload'])
      end

      headers = if (headers_attribute = options[:headers_attribute])
        headers_attribute.example(context + ['headers'])
      else
        {}
      end

      name = options[:name]

      filename = if (filename_attribute = options[:filename_attribute])
        filename_attribute.example(context + ['filename'])
      else
        nil
      end

      self.new(payload, headers, name: name, filename: filename,
               payload_attribute: payload_attribute,
               headers_attribute: headers_attribute,
               filename_attribute: filename_attribute)
    end
    
    def self.describe(shallow=true, example: nil, options:{})
      hash = super(shallow, example: example)

      if (payload_attribute = options[:payload_attribute])
        payload_example = example.payload if example
        hash[:payload] = payload_attribute.describe(shallow, example: payload_example)
      end
      if (headers_attribute = options[:headers_attribute])
        headers_example = example.headers if example
        hash[:headers] = headers_attribute.describe(shallow, example: headers_example)
      end
      if (filename_attribute = options[:filename_attribute])
        filename_example = example.filename if example
        hash[:filename] = filename_attribute.describe(shallow, example: filename_example)
      end

      hash
    end

    def initialize(body, headers={}, name: nil, filename: nil, payload_attribute: nil, headers_attribute: nil, filename_attribute: nil)
      @name = name
      @body = body
      @headers = headers
      @default_handler = Praxis::Application.instance.handlers['json']

      if content_type.nil?
        self.content_type = 'text/plain'
      end

      @filename = filename

      @payload_attribute = payload_attribute
      @headers_attribute = headers_attribute
      @filename_attribute = filename_attribute

      reset_content_disposition
    end

    alias_method :payload, :body
    alias_method :payload=, :body=

    def attribute=(attribute)
      unless self.kind_of?(attribute.type)
        raise ArgumentError, "invalid attribute type #{attribute.type}"
      end

      if attribute.options.key? :payload_attribute
        @payload_attribute = attribute.options[:payload_attribute]
      end

      if attribute.options.key? :headers_attribute
        @headers_attribute = attribute.options[:headers_attribute]
      end

      if attribute.options.key? :filename_attribute
        @filename_attribute = attribute.options[:filename_attribute]
      end

    end

    def load_payload(context=Attributor::DEFAULT_ROOT_CONTEXT)
      if self.payload_attribute
        value = if self.payload.kind_of?(String)
          handler.parse(self.payload)
        else
          self.payload
        end

        self.payload = self.payload_attribute.load(value)
      end
    end

    def load_headers(context=Attributor::DEFAULT_ROOT_CONTEXT)
      if self.headers_attribute
        self.headers = self.headers_attribute.load(self.headers)
      end
    end

    # Determine the content type of this response.
    #
    # @return [MediaTypeIdentifier]
    def content_type
      @content_type ||= MediaTypeIdentifier.load(headers['Content-Type']).freeze
    end

    # Set the content type for this response.
    # @todo DRY this out (also used in Response)
    #
    # @return [String]
    # @param [String,MediaTypeIdentifier] identifier
    def content_type=(identifier)
      @content_type = nil
      headers['Content-Type'] = MediaTypeIdentifier.load(identifier).to_s
    end

    def status
      @headers['Status'].to_i
    end

    def encode!
      case @body
      when Hash, Array
        # response payload is structured data; transform it into an entity using the handler
        # implied by the response's media type. If no handler is registered for this
        # name, assume JSON as a default handler.
        @body = JSON.pretty_generate(@body)
      end
    end

    def validate_headers(context=Attributor::DEFAULT_ROOT_CONTEXT)
      return [] unless self.headers_attribute

      self.headers_attribute.validate(headers, context + ['headers'])
    end

    def validate_payload(context=Attributor::DEFAULT_ROOT_CONTEXT)
      return [] unless self.payload_attribute

      self.payload_attribute.validate(payload, context + ['payload'])
    end

    def validate_filename(context=Attributor::DEFAULT_ROOT_CONTEXT)
      return [] unless self.filename_attribute

      self.filename_attribute.validate(filename, context + ['filename'])
    end

    def validate(context=Attributor::DEFAULT_ROOT_CONTEXT)
      errors = validate_headers(context)
      errors.push *validate_payload(context)
      errors.push *validate_filename(context)
    end

    def reset_content_disposition
      self.headers['Content-Disposition'] = begin
        disposition = "form-data; name=#{name}"
        if filename
          disposition += "; filename=#{filename}"
        end

        disposition
      end
    end


    def name=(name)
      @name = name
      reset_content_disposition
      name
    end

    def filename=(filename)
      @filename = filename
      reset_content_disposition
      filename
    end

    def handler
      handlers = Praxis::Application.instance.handlers
      (content_type && handlers[content_type.handler_name]) || @default_handler
    end

    # Determine an appropriate default content_type for this part given
    # the preferred handler_name, if possible.
    # 
    # Considers any pre-defined set of values on the content_type attributge
    # of the headers.
    def derive_content_type(handler_name)
      possible_values = if self.content_type.match 'text/plain'
        _, content_type_attribute = self.headers_attribute && self.headers_attribute.attributes.find { |k,v| k.to_s =~ /^content[-_]{1}type$/i }
        if content_type_attribute && content_type_attribute.options.key?(:values)
          content_type_attribute.options[:values]
        else
          []
        end
      else
        [self.content_type]
      end

      # generic default encoding is the best we can do
      if possible_values.empty?
        return MediaTypeIdentifier.load("application/#{handler_name}")
      end

      # if any defined value match the preferred handler_name, return it
      possible_values.each do |ct|
        mti = MediaTypeIdentifier.load(ct)
        return mti if mti.handler_name == handler_name
      end

      # otherwise, pick the first
      pick = MediaTypeIdentifier.load(possible_values.first)

      # and return that one if it already corresponds to a registered handler
      # otherwise, add the encoding
      if Praxis::Application.instance.handlers.include?(pick.handler_name)
        return pick
      else
        return pick + handler_name
      end

    end

    def dump(default_format: nil, **opts)
      original_content_type = self.content_type

      body = self.payload_attribute.dump(self.payload, **opts)

      body_string = case body
      when Hash, Array
        if default_format
          self.content_type = derive_content_type(default_format)
        end

        self.handler.generate(body)
      else
        body
      end

      header_string = self.headers.collect do |name, value|
        "#{name}: #{value}"
      end.join("\r\n")


      "#{header_string}\r\n\r\n#{body_string}"
    ensure
      self.content_type = original_content_type
    end

  end
end
