module Praxis
  class Multipart < Attributor::Hash

    @key_type = Attributor::String

    def self.inherited(klass)
      warn "DEPRECATION: Praxis::Multipart is deprecated and will be removed in 1.0. Use Praxis::Types::MultipartArray instead"
      super
    end

    def self.load(value, context=Attributor::DEFAULT_ROOT_CONTEXT, content_type:nil)
      return value if value.kind_of?(self) || value.nil?

      unless (value.kind_of?(::String) && ! content_type.nil?)
        raise Attributor::CoercionError, context: context, from: value.class, to: self.name, value: value
      end

      headers = {'Content-Type' => content_type}
      parser = MultipartParser.new(headers, value)
      preamble, parts = parser.parse

      parts_hash = parts.each_with_object({}) do |part, hash|
        hash[part.name] = self.backconvert_part_data(part)
      end

      hash = Hash[parts_hash.collect { |name, part| [name, part.body] }]

      instance = super(hash, context, **options)

      instance.preamble = preamble
      instance.parts = parts_hash
      instance.headers = headers

      instance
    end

    def self.backconvert_part_data(part)
      filename = part.filename
      body = part.payload
      name = part.name

      content_type = part.headers['Content-Type']

      # cheat and unparse the headers back to a head string. should be ok...
      head = part.headers.collect {|k,v| "#{k}: #{v}" }.join("\r\n")

      data = nil
      if filename == ""
        # filename is blank which means no file has been selected
        return data
      elsif filename
        body.rewind

        data = {:filename => filename, :type => content_type,
                :name => name, :tempfile => body, :head => head}
      elsif !filename && content_type && body.is_a?(IO)
        body.rewind

        # Generic multipart cases, not coming from a form
        data = {:type => content_type,
                :name => name, :tempfile => body, :head => head}
      else
        data = body
      end

      part.payload = data
      part
    end


    def self.example(context=nil, options: {})
      form = MIME::Multipart::FormData.new

      super(context, options: options).each do |k,v|
        body = if v.respond_to?(:dump) && !v.kind_of?(String)
          JSON.pretty_generate(v.dump)
        else
          v
        end

        entity = MIME::Text.new(body)

        form.add entity, String(k)
      end

      content_type = form.headers.get('Content-Type')
      body = form.body.to_s

      self.load(body, context, content_type: content_type)
    end

    attr_accessor :preamble
    attr_accessor :parts
    attr_accessor :headers


    def validate(context=Attributor::DEFAULT_ROOT_CONTEXT)
      super
    end

    def self.describe(shallow = false, **opts)
      hash = super(**opts)
      hash.merge!(family: 'multipart')
      hash
    end
  end


end
