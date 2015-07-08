require 'praxis/types/multipart_array/part_definition'

module Praxis
  module Types
    class MultipartArray < Attributor::Collection
      include Types::MediaTypeCommon

      @member_type = Praxis::MultipartPart
      @payload_type = Attributor::String
      @name_type = Attributor::String
      @attributes = FuzzyHash.new.freeze
      @identifier = MediaTypeIdentifier.load('multipart/form-data').freeze

      def self.inherited(klass)
        klass.instance_eval do
          @attributes = FuzzyHash.new
          @saved_blocks = []
          @multiple = []
          @options = {}

          @payload_type = Attributor::String
          @name_type = Attributor::String
          @member_type = Praxis::MultipartPart

          @payload_attribute = nil
          @part_attribute = nil

          @identifier = MediaTypeIdentifier.load('multipart/form-data').freeze

        end
      end

      class << self
        attr_reader :attributes
        attr_reader :multiple
        attr_reader :options
        attr_reader :identifier
      end

      def self.constructable?
        true
      end

      def self.construct(constructor_block, _options={})
        Class.new(self, &constructor_block)
      end

      def self.name_type(type=nil)
        return @name_type if type.nil?

        @name_type = Attributor.resolve_type type
      end

      def self.payload_type(type=nil)
        return @payload_type if type.nil?

        @payload_type = Attributor.resolve_type(type)
        @payload_attribute = nil
        @part_attribute = nil
        @payload_type
      end

      def self.payload_attribute
        @payload_attribute ||= Attributor::Attribute.new(@payload_type)
      end

      def self.part_attribute
        @part_attribute ||= Attributor::Attribute.new(Praxis::MultipartPart, payload_attribute: self.payload_attribute)
      end

      def self.part(name, payload_type=nil, multiple: false, filename: false, **opts, &block)
        @attributes.default_proc = nil

        if name.kind_of?(Regexp)
          raise 'part with regexp name may not take :multiple option' if multiple
          raise 'part with regexp name may not be required' if opts[:required] == true
        end

        self.multiple << name if multiple

        compiler = Attributor::DSLCompiler.new(self, opts)

        if filename
          filename_attribute = compiler.define('filename', String, required: true)
        end

        if block_given?
          definition = PartDefinition.new(&block)
          payload_attribute = definition.payload_attribute
          header_attribute = definition.headers_attribute
          filename_attribute = definition.filename_attribute || filename_attribute

          self.attributes[name] = compiler.define(name, Praxis::MultipartPart,
                                                  payload_attribute: payload_attribute,
                                                  headers_attribute: header_attribute,
                                                  filename_attribute: filename_attribute
                                                  )
        else
          payload_attribute = compiler.define(name, payload_type || self.payload_type, **opts)
          self.attributes[name] = compiler.define(name, Praxis::MultipartPart,
                                                  payload_attribute: payload_attribute,
                                                  filename_attribute: filename_attribute
                                                  )
        end
      end

      def self.file(name, payload_type=nil, filename: nil, **opts, &block)
        self.part(name, payload_type=nil, filename: true, **opts, &block)
      end

      def self.load(value, context=Attributor::DEFAULT_ROOT_CONTEXT, content_type:nil)
        return value if value.kind_of?(self) || value.nil?

        if value.kind_of?(::String) && content_type.nil?
          raise ArgumentError, "content_type is required to load values of type String for #{Attributor.type_name(self)}"
        end

        parser = Praxis::MultipartParser.new({'Content-Type' => content_type}, value)
        preamble, parts = parser.parse

        instance = self.new
        instance.push(*parts)

        instance.preamble = preamble
        instance.content_type = content_type

        instance
      end

      def self.example(context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
        example = self.new

        self.attributes.each do |name, attribute|
          next if name.kind_of? Regexp
          sub_context = self.generate_subcontext(context, name)

          part = attribute.example(sub_context)
          part.name = name
          example.push part

          if self.multiple.include? name
            part = attribute.example(sub_context + ['2'])
            part.name = name
            example.push part
          end
        end

        example
      end


      def self.describe(shallow=true, example: nil)
        type_name = Attributor.type_name(self)
        hash = {
          name: type_name.gsub(Attributor::MODULE_PREFIX_REGEX, ''),
          family: self.family,
          id: self.id
        }
        hash[:example] = example if example

        hash[:part_name] = {type: name_type.describe(true)}

        unless shallow
          hash[:attributes] = {} if self.attributes.keys.any? { |name| name.kind_of? String}
          hash[:pattern_attributes] = {} if self.attributes.keys.any? { |name| name.kind_of? Regexp}

          if hash.key?(:attributes) || hash.key?(:pattern_attributes)
            self.describe_attributes(shallow, example: example).each do |name, sub_hash|
              if self.multiple.include?(name)
                #sub_hash[:options] ||= {}
                #sub_hash[:multiple] = true
              end

              case name
              when String
                hash[:attributes][name] = sub_hash
              when Regexp
                hash[:pattern_attributes][name.source] = sub_hash
              end

            end
          else
            hash[:part_payload] = {type: payload_type.describe(true)}
          end
        end
        hash
      end

      def self.describe_attributes(shallow=true, example: nil)
        self.attributes.each_with_object({}) do |(part_name, part_attribute), parts|
          sub_hash = part_attribute.describe(shallow, example: example)
          if (options = sub_hash.delete(:options))
            sub_hash[:options] = {}
            if self.multiple.include?(part_name)
              sub_hash[:options][:multiple] = true
            end

            if (payload_attribute = options.delete :payload_attribute)
              if (required = payload_attribute.options[:required])
                sub_hash[:options][:required] = true
              end
            end
          end

          sub_hash[:type] = MultipartPart.describe(shallow, example:example, options: part_attribute.options)
          #sub_example = example.get(sub_name) if example

          parts[part_name] = sub_hash
        end
      end

      attr_accessor :preamble
      attr_reader :content_type

      def initialize(content_type: self.class.identifier)
        self.content_type = content_type
      end

      def content_type=(content_type)
        @content_type = MediaTypeIdentifier.load(content_type)
        if @content_type.parameters.get('boundary').nil?
          @content_type.parameters.set 'boundary', 'Boundary_puppies'
        end
        @content_type
      end

      def payload_type
        self.class.payload_type
      end

      def push(*parts, context: Attributor::DEFAULT_ROOT_CONTEXT)
        part, *rest = parts
        if rest.any?
          return self.push(part, context: context).push(*rest, context:context)
        end

        original_context = context

        part.name = self.class.name_type.load(part.name, self.class.generate_subcontext(context, part.name))
        key = part.name

        context = self.class.generate_subcontext(context, key)

        # If no attributes are defined, we always use the default
        # payload_attribute, otherwise we constrain the parts
        # to the defined names.
        attribute = if self.class.attributes.empty?
          self.class.part_attribute
        elsif (default_thingy = self.class.attributes[key])
          default_thingy
        else
          nil
        end

        if attribute
          part.attribute = attribute
          part.load_payload(context + ['payload'])
          part.load_headers(context + ['headers'])
          return self << part
        elsif self.class.options[:case_insensitive_load]
          name = self.class.attributes.keys.find do |k|
            k.kind_of?(String) && key.downcase == k.downcase
          end
          if name
            part.name = name
            return self.push(part, context: original_context)
          end
        end

        raise Attributor::AttributorException, "Unknown part name received: #{key.inspect} while loading #{Attributor.humanize_context(context)}"
      end

      def part(name)
        if self.class.multiple.include?(name)
          self.select { |i| i.name == name }
        else
          self.find { |i| i.name == name }
        end
      end

      def validate(context=Attributor::DEFAULT_ROOT_CONTEXT)
        errors = self.each_with_index.each_with_object([]) do |(part, idx), errors|
          sub_context = if part.name
            self.class.generate_subcontext(context, part.name)
          else
            context + ["at(#{idx})"]
          end

          errors.push *part.validate(sub_context)
        end

        self.class.attributes.each do |name, attribute|
          payload_attribute = attribute.options[:payload_attribute]
          next unless payload_attribute.options[:required]
          next if self.part(name)

          sub_context = self.class.generate_subcontext(context, name)
          errors.push *payload_attribute.validate_missing_value(sub_context)
        end

        errors
      end


      def dump(**opts)
        boundary = content_type.parameters.get 'boundary'

        parts = self.collect do |part|
          part.dump(**opts)
        end

        all_entities = parts.join("\r\n--#{boundary}\r\n")
        "--#{boundary}\r\n#{all_entities}\r\n--#{boundary}--\r\n"
      end


    end
  end
end
