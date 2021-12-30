# frozen_string_literal: true

require 'set'
require 'active_support/core_ext/object/blank'

module Praxis
  # Ruby object representation of an Internet Media Type Identifier as defined by
  # RFC6838; also known as MIME types due to their origin in RFC2046 (the
  # MIME specification).
  class MediaTypeIdentifier < Attributor::Model
    # Postel's principle encourages us to accept anything that MIGHT be an identifier, although
    # the syntax for type identifiers is substantially narrower than what we accept there.
    #
    # Note that this ONLY matches type, subtype and suffix; we handle options differently.
    VALID_TYPE = %r{^\s*(?<type>[^/]+)/(?<subtype>[^+]+)(\+(?<suffix>[^; ]+))?\s*$}x.freeze

    # Pattern that separates parameters of a media type from each other, and from the base identifier.
    PARAMETER_SEPARATOR = /\s*;\s*/x.freeze

    # Pattern used to identify the first "word" when we encounter a malformed type identifier, so
    # we can apply a heuristic and assume the user meant "application/XYZ".
    WORD_SEPARATOR = /[^a-z0-9-]/i.freeze

    # Pattern that lets us strip quotes from parameter values.
    QUOTED_STRING = /^".*"$/.freeze

    # Token that indicates a media-type component that matches anything.
    WILDCARD = '*'

    # Inner type representing semicolon-delimited parameters.
    Parameters = Attributor::Hash.of(key: String)

    attributes do
      attribute :type, Attributor::String, default: 'application', description: 'RFC2046 media type'
      attribute :subtype, Attributor::String, default: '*', description: 'RFC2046 media subtype', example: 'vnd.widget'
      attribute :suffix, Attributor::String, default: '', description: 'RFC6838 structured-syntax suffix', example: 'json'
      attribute :parameters, Parameters, default: {}, description: 'Type-specific parameters', example: "{'type' => 'collection'}"
    end

    # Parse a media type identifier from a String, or load it from a Hash or Model. Assume malformed
    # types represent a subtype, e.g. "nachos" => application/nachos"
    #
    # @param [String,Hash,Attributor::Model] value
    # @return [MediaTypeIdentifier]
    # @see Attributor::Model#load
    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, recurse: false, **options)
      case value
      when String
        return nil if value.blank?

        base, *parameters = value.split(PARAMETER_SEPARATOR)
        match = VALID_TYPE.match(base)

        obj = new
        if match
          parameters = parameters.each_with_object({}) do |e, h|
            k, v = e.split('=', 2)
            v = v[1...-1] if v =~ QUOTED_STRING
            h[k] = v
          end

          obj.type = match[:type]
          obj.subtype = match[:subtype]
          obj.suffix = match[:suffix]
          obj.parameters = parameters
        else
          obj.type = 'application'
          obj.subtype = base.split(WORD_SEPARATOR, 2).first
          obj.suffix = String.new
          obj.parameters = {}
        end
        obj
      when nil
        nil
      else
        super
      end
    end

    # Determine whether another identifier is compatible with (i.e. is a subset or specialization of)
    # this identifier.
    #
    # @return [Boolean] true if this type is compatible with other, false otherwise
    #
    # @param [MediaTypeIdentifier,String] other
    #
    # @example match anything
    #      MediaTypeIdentifier.load('*/*').match('application/icecream+cone; flavor=vanilla') # => true
    #
    # @example match a subtype wildcard
    #      MediaTypeIdentifier.load('image/*').match('image/jpeg') # => true
    #
    # @example match a specific type irrespective of structured syntax
    #      MediaTypeIdentifier.load('application/vnd.widget').match('application/vnd.widget+json') # => true
    #
    # @example match a specific type, respective of important parameters but irrespective of extra parameters or structured syntax
    #      MediaTypeIdentifier.load('application/vnd.widget; type=collection').match('application/vnd.widget+json; material=steel; type=collection') # => true
    def match(other)
      other = MediaTypeIdentifier.load(other)

      return false if other.nil?
      return false unless type == other.type || type == WILDCARD
      return false unless subtype == other.subtype || subtype == WILDCARD
      return false unless suffix.empty? || suffix == other.suffix

      parameters.each_pair do |k, v|
        return false unless other.parameters[k] == v
      end

      true
    end

    # Determine whether this type is compatible with (i.e. is a subset or specialization of) another identifier.
    # This is the same operation as #match, but with the position of the operands switched -- analogous to
    # "Regexp#match(String)" vs "String =~ Regexp".
    #
    # @return [Boolean] true if this type is compatible with other, false otherwise
    #
    # @param [MediaTypeIdentifier,String] other
    #
    # @see #match
    def =~(other)
      other.match(self)
    end

    # @return [String] canonicalized representation of the media type including all suffixes and parameters
    def to_s
      # Our handcrafted media types consist of a rich chocolatey center
      s = String.new("#{type}/#{subtype}")

      # coated in a hard candy shell
      s << '+' << suffix unless suffix.empty?

      # and encrusted with lexically-ordered sprinkles
      unless parameters.empty?
        s << '; '
        s << parameters.keys.sort.map { |k| "#{k}=#{parameters[k]}" }.join('; ')
      end

      # May contain peanuts, tree nuts, soy, dairy, sawdust or glue
      s
    end

    alias to_str to_s

    # If parameters are empty, return self; otherwise return a new object consisting of this type
    # minus parameters.
    #
    # @return [MediaTypeIdentifier]
    def without_parameters
      if parameters.empty?
        self
      else
        val = { type: type, subtype: subtype, suffix: suffix }
        MediaTypeIdentifier.load(val)
      end
    end

    # Make an educated guess about the structured-syntax encoding implied by this media type,
    # which in turn governs which handler should be used to parse and generate media of this
    # type.
    #
    # If a suffix e.g. "+json" is present, return it. Otherwise, return the subtype.
    #
    # @return [String] a type identifier fragment e.g. "json" or "xml" that MAY indicate encoding
    #
    # @see xxx
    def handler_name
      suffix.empty? ? subtype : suffix
    end

    # Extend this type identifier by adding a suffix or parameter(s); return a new type identifier.
    #
    # @param [String] extension an optional suffix, followed by an optional semicolon-separated list of name="value" pairs
    # @return [MediaTypeIdentifier]
    #
    # @raise [ArgumentError] when an invalid string is passed (e.g. containing neither parameters nor a suffix)
    #
    # @example Indicate JSON structured syntax
    #     MediaTypeIdentifier.new('application/vnd.widget') + 'json' # => 'application/vnd.widget+json'
    #
    # @example Indicate UTF8 encoding
    #     MediaTypeIdentifier.new('application/vnd.widget') + 'charset=UTF8' # => 'application/vnd.widget; charset="UTF8"'
    def +(other)
      parameters = other.split(PARAMETER_SEPARATOR)
      # remove useless initial '; '
      parameters.shift if parameters.first && parameters.first.empty?

      raise ArgumentError, 'Must pass a type identifier suffix and/or parameters' if parameters.empty?

      suffix = parameters.shift unless parameters.first.include?('=')
      # remove redundant '+'
      suffix = suffix[1..-1] if suffix && suffix[0] == '+'

      parameters = parameters.each_with_object({}) do |e, h|
        k, v = e.split('=', 2)
        v = v[1...-1] if v =~ /^".*"$/
        h[k] = v
        h
      end
      parameters = Parameters.load(parameters)

      obj = self.class.new
      obj.type = type
      obj.subtype = subtype
      target_suffix = suffix || self.suffix
      obj.suffix = redundant_suffix(target_suffix) ? String.new : target_suffix
      obj.parameters = self.parameters.merge(parameters)

      obj
    end

    def redundant_suffix(suffix)
      # application/json does not need to be suffixed with +json (same for application/xml)
      # we're supporting text/json and text/xml for older formats as well
      return true if (type == 'application' || type == 'text') && subtype == suffix

      false
    end
  end
end
