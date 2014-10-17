module Praxis

  module StructCollection
    def self.included(klass)
      klass.instance_eval do
        include(Enumerable)
      end
    end

    def _members=(members)
      @members = members
    end

    def _members
      @members || []
    end

    def each
      _members.each { |member| yield(member) }
    end
  end

  class MediaTypeCollection < MediaType
    include Enumerable

    class << self
      attr_accessor :member_attribute
    end
    
    def self._finalize!
      super

      if const_defined?(:Struct, false)
        self::Struct.instance_eval do
          include StructCollection
        end
      end

    end

    def self.member_type(type=nil)
      return ( @member_attribute ? @member_attribute.type : nil) unless type
      raise ArgumentError, "invalid type: #{type.name}" unless type < MediaType

      member_options = {}
      @member_attribute = Attributor::Attribute.new type, member_options
    end

    def self.example(context=nil, options: {})
      result = super

      context = case context
      when nil
        ["#{self.name}-#{values.object_id.to_s}"]
      when ::String
        [context]
      else
        context
      end

      members = []
      size = rand(3) + 1


      size.times do |i|
        subcontext = context + ["at(#{i})"]
        members << @member_attribute.example(subcontext)
      end


      result.object._members = members
      result
    end

    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      if value.kind_of?(String)
        value = JSON.parse(value)
      end

      case value
      when nil, self
        value
      when Hash
        # Need to parse/deserialize first
        self.new(self.attribute.load(value,context, **options))
      when Array, Praxis::Mapper::ResourceDecorator
        object = self.attribute.load({})
        object._members = value.collect { |subvalue| @member_attribute.load(subvalue) }
        self.new(object)
      else
        # Just wrap whatever value
        self.new(value)
      end
    end

    def self.describe(shallow = false)
      hash = super
      hash[:member_attribute] = member_attribute.describe(true)
      hash
    end

    def self.member_view(name, using: nil)
      if using
        member_view = self.member_type.view(using)
        return self.views[name] = CollectionView.new(name, self, member_view)
      end

      self.views[name]
    end


    def each
      @object.each { |member| yield(member) }
    end


    def validate(context=Attributor::DEFAULT_ROOT_CONTEXT)
      errors = super
      self.each_with_object(errors) do |member, errors|
        errors.push(*member.validate(context))
      end
    end

  end
end
