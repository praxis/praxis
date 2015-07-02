module Praxis
  module Handlers
    class XML
      # Construct an XML handler and initialize any related libraries.
      #
      # @raise [Praxis::Exceptions::InvalidConfiguration] if the handler is unsupported
      def initialize
        require 'nokogiri'
        require 'builder'
        require 'active_support'
        ActiveSupport::XmlMini.backend = 'Nokogiri'
      rescue LoadError
        raise Praxis::Exceptions::InvalidConfiguration,
          "XML handler depends on builder ~> 3.2 and nokogiri ~> 1.6; please add them to your Gemfile"
      end

      # Parse an XML document into structured data.
      #
      # @param [String] document
      # @return [Hash,Array] the structured-data representation of the document
      def parse(document)
        p = Nokogiri::XML(document)
        process(p.root, p.root.attributes['type'])
      end

      # Generate a pretty-printed XML document from structured data.
      #
      # @param [Hash,Array] structured_data
      # @return [String]
      def generate(structured_data)
        # courtesy of active_support + builder
        structured_data.to_xml
      end

      protected

      # Transform a Nokogiri DOM object into structured data.
      def process(node, type_attribute)
        type = type_attribute.value if type_attribute

        case type
        when nil
          if (node.children.size == 1 && node.child.text?) || node.children.size == 0
            # leaf text node
            return node.content
          else
            # A hash
            return node.children.each_with_object({}) do |child, hash|
              next unless child.element? # There might be text fragments like newlines...spaces
              hash[child.name.underscore] = process(child, child.attributes['type'])
            end
          end
        when "array"
          return node.children.each_with_object([]) do |child, arr|
            next unless child.element? # There might be text fragments like newlines...spaces
            arr << process(child, child.attributes['type'])
          end
        when "integer"
          return Integer(node.content)
        when "symbol"
          return node.content.to_sym
        when "decimal"
          return BigDecimal.new(node.content)
        when "float"
          return Float(node.content)
        when "boolean"
          return ((node.content == "false") ? false : true)
        when "date"
          return Date.parse(node.content)
        when "dateTime"
          return DateTime.parse(node.content)
        else
          raise ArgumentError, "Unknown attribute type: #{type}"
        end
      end
    end
  end
end
