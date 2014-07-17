module PartType
end

class FileUpload < Attributor::String
  include PartType



end

module Praxis

  class Multipart < Attributor::Hash

    @key_type = Attributor::String

    def self.load(value, context=Attributor::DEFAULT_ROOT_CONTEXT, content_type:)
      #return super if content_type.nil?

      headers = {'Content-Type' => content_type}

      parser = MultipartParser.new(headers, value)
      preamble, parts = parser.parse

      hash = Hash[parts.collect { |name, part| [name, part.body] }]

      instance = super(hash, context=Attributor::DEFAULT_ROOT_CONTEXT, **options)

      instance.preamble = preamble
      instance.parts = parts
      instance.headers = headers

      instance
    end
    #
    # def self.from_hash(parts, context)
    #   hash = Hash[parts.collect { |name, part| [name, part.body] }]
    #   super(hash, context)
    # end

    attr_accessor :preamble
    attr_accessor :parts
    attr_accessor :headers

    def validate(*args)
      []
    end

    # FIXME: add a part in here
    #def []=(k, v)
    #end

  end


end
