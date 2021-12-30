# frozen_string_literal: true
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
        attr_reader :attributes, :multiple, :options, :identifier
      end

      def self.constructable?
        true
      end

      def self.construct(constructor_block, _options = {})
        Class.new(self, &constructor_block)
      end

      def self.name_type(type = nil)
        return @name_type if type.nil?

        @name_type = Attributor.resolve_type type
      end

      def self.payload_type(type = nil, **opts, &block)
        if type.nil?
          if block_given?
            type = Attributor::Struct
          else
            return @payload_type
          end
        end
        @payload_type = Attributor.resolve_type(type)
        @payload_attribute = Attributor::Attribute.new(@payload_type, **opts, &block)
        @part_attribute = nil
        @payload_type
      end

      def self.payload_attribute
        @payload_attribute ||= Attributor::Attribute.new(@payload_type)
      end

      def self.part_attribute
        @part_attribute ||= Attributor::Attribute.new(Praxis::MultipartPart, payload_attribute: payload_attribute)
      end

      def self.part(name, payload_type = nil, multiple: false, filename: false, **opts, &block)
        @attributes.default_proc = nil

        if name.is_a?(Regexp)
          raise 'part with regexp name may not take :multiple option' if multiple
          raise 'part with regexp name may not be required' if opts[:required] == true
        end

        self.multiple << name if multiple

        compiler = Attributor::DSLCompiler.new(self, **opts)

        filename_attribute = compiler.define('filename', String, required: true) if filename

        if block_given?
          definition = PartDefinition.new(&block)
          payload_attribute = definition.payload_attribute
          header_attribute = definition.headers_attribute
          filename_attribute = definition.filename_attribute || filename_attribute

          attributes[name] = compiler.define(name, Praxis::MultipartPart,
                                             payload_attribute: payload_attribute,
                                             headers_attribute: header_attribute,
                                             filename_attribute: filename_attribute)
        else
          payload_attribute = compiler.define(name, payload_type || self.payload_type, **opts)
          attributes[name] = compiler.define(name, Praxis::MultipartPart,
                                             payload_attribute: payload_attribute,
                                             filename_attribute: filename_attribute)
        end
      end

      def self.file(name, payload_type = nil, filename: nil, **opts, &block)
        part(name, payload_type, filename: true, **opts, &block)
      end

      def self.load(value, _context = Attributor::DEFAULT_ROOT_CONTEXT, content_type: nil)
        return value if value.is_a?(self) || value.nil?

        raise ArgumentError, "content_type is required to load values of type String for #{Attributor.type_name(self)}" if value.is_a?(::String) && content_type.nil?

        parser = Praxis::MultipartParser.new({ 'Content-Type' => content_type }, value)
        preamble, parts = parser.parse

        instance = new
        instance.push(*parts)

        instance.preamble = preamble
        instance.content_type = content_type

        instance
      end

      def self.example(context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
        example = new

        attributes.each do |name, attribute|
          next if name.is_a? Regexp

          sub_context = generate_subcontext(context, name)

          part = attribute.example(sub_context)
          part.name = name
          example.push part

          next unless multiple.include? name

          part = attribute.example(sub_context + ['2'])
          part.name = name
          example.push part
        end

        example
      end

      def self.json_schema_type
        :object
      end

      # Multipart request bodies are special in OPEN API
      # schema:            # Request payload
      # type: object
      # properties:      # Request parts
      #   id:            # Part 1 (string value)
      #     type: string
      #     format: uuid
      #   address:       # Part2 (object)
      #     type: object
      #     properties:
      #       street:
      #         type: string
      #       city:
      #         type: string
      #   profileImage:  # Part 3 (an image)
      #     type: string
      #     format: binary
      #
      # NOTE: not sure if this
      def self.as_openapi_request_body(attribute_options: {})
        hash = { type: json_schema_type }
        opts = options.merge(attribute_options)
        hash[:description] = opts[:description] if opts[:description]
        hash[:default] = opts[:default] if opts[:default]

        unless attributes.empty?
          props = {}
          encoding = {}
          attributes.each do |part_name, part_attribute|
            part_example = part_attribute.example
            key_to_use = part_name.is_a?(Regexp) ? part_name.source : part_name

            part_info = {}
            if (payload_attribute = part_attribute.options[:payload_attribute])
              props[key_to_use] = payload_attribute.as_json_schema(example: part_example.payload)
            end
            # {
            # contentType: 'fff',
            # headers: {
            #   custom1: 'safd'
            # }
            next unless (headers_attribute = part_attribute.options[:headers_attribute])

            # Does this 'Content-Type' string check work?...can it be a symbol? what does it mean anyway?
            encoding[key_to_use][:contentType] = headers_attribute['Content-Type'] if headers_attribute['Content-Type']
            # TODO?rethink? ...is this correct?: att a 'headers' key with some header schemas if this part have some
            encoding[key_to_use]['headers'] = headers_attribute.as_json_schema(example: part_example.headers)
          end

          hash[:properties] = props
          hash[:encoding] = encoding unless encoding.empty?
        end
        hash
      end

      def self.as_json_schema(shallow: false, example: nil, attribute_options: {})
        as_openapi_request_body(attribute_options: attribute_options)
      end

      def self.describe(shallow = true, example: nil)
        type_name = Attributor.type_name(self)
        hash = {
          name: type_name.gsub(Attributor::MODULE_PREFIX_REGEX, ''),
          family: family,
          id: id
        }
        hash[:example] = example if example

        hash[:part_name] = { type: name_type.describe(true) }

        unless shallow
          hash[:attributes] = {} if attributes.keys.any? { |name| name.is_a? String }
          hash[:pattern_attributes] = {} if attributes.keys.any? { |name| name.is_a? Regexp }

          if hash.key?(:attributes) || hash.key?(:pattern_attributes)
            describe_attributes(shallow, example: example).each do |name, sub_hash|
              case name
              when String
                hash[:attributes][name] = sub_hash
              when Regexp
                hash[:pattern_attributes][name.source] = sub_hash
              end
            end
          else
            hash[:part_payload] = { type: payload_type.describe(true) }
          end
        end
        hash
      end

      def self.describe_attributes(shallow = true, example: nil)
        attributes.each_with_object({}) do |(part_name, part_attribute), parts|
          sub_example = example.part(part_name) if example
          sub_example = sub_example.first if sub_example && multiple.include?(part_name)

          sub_hash = part_attribute.describe(shallow, example: sub_example)

          if (options = sub_hash.delete(:options))
            sub_hash[:options] = {}
            sub_hash[:options][:multiple] = true if multiple.include?(part_name)

            if (payload_attribute = options.delete :payload_attribute) && (required = payload_attribute.options[:required])
              sub_hash[:options][:required] = true
            end
          end

          sub_hash[:type] = MultipartPart.describe(shallow, example: sub_example, options: part_attribute.options)

          parts[part_name] = sub_hash
        end
      end

      attr_accessor :preamble
      attr_reader :content_type

      def initialize(content_type: self.class.identifier.to_s)
        self.content_type = content_type
      end

      def content_type=(content_type)
        @content_type = MediaTypeIdentifier.load(content_type)
        @content_type.parameters.set 'boundary', 'Boundary_puppies' if @content_type.parameters.get('boundary').nil?
        @content_type
      end

      def payload_type
        self.class.payload_type
      end

      def push(*parts, context: Attributor::DEFAULT_ROOT_CONTEXT)
        part, *rest = parts
        return push(part, context: context).push(*rest, context: context) if rest.any?

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
                    end

        if attribute
          part.attribute = attribute
          part.load_payload(context + ['payload'])
          part.load_headers(context + ['headers'])
          return self << part
        elsif self.class.options[:case_insensitive_load]
          name = self.class.attributes.keys.find do |k|
            k.is_a?(String) && key.downcase == k.downcase
          end
          if name
            part.name = name
            return push(part, context: original_context)
          end
        end

        raise Attributor::AttributorException, "Unknown part name received: #{key.inspect} while loading #{Attributor.humanize_context(context)}"
      end

      def part(name)
        if self.class.multiple.include?(name)
          self.select { |i| i.name == name }
        else
          find { |i| i.name == name }
        end
      end

      def part?(name)
        any? { |i| i.name == name }
      end

      def validate(context = Attributor::DEFAULT_ROOT_CONTEXT)
        errors = each_with_index.each_with_object([]) do |(part, idx), errors|
          sub_context = if part.name
                          self.class.generate_subcontext(context, part.name)
                        else
                          context + ["at(#{idx})"]
                        end

          errors.push(*part.validate(sub_context))
        end

        self.class.attributes.each do |name, attribute|
          payload_attribute = attribute.options[:payload_attribute]

          if !part?(name)
            if payload_attribute.options[:required]
              sub_context = self.class.generate_subcontext(context, name)
              errors.push "Attribute #{Attributor.humanize_context(sub_context)} is required"
            end
            # Return, don't bother checking nullability as it hasn't been provided
          elsif !self.part(name) && !Attribute.nullable_attribute?(payload_attribute.options)
            sub_context = self.class.generate_subcontext(context, name)
            errors.push "Attribute #{Attributor.humanize_context(sub_context)} is not nullable"
          end
        end
        errors
      end

      def self.dump(value, **opts)
        value.dump(**opts)
      end

      def dump(**opts)
        boundary = content_type.parameters.get 'boundary'

        parts = collect do |part|
          part.dump(**opts)
        end

        all_entities = parts.join("\r\n--#{boundary}\r\n")
        "--#{boundary}\r\n#{all_entities}\r\n--#{boundary}--\r\n"
      end
    end
  end
end
