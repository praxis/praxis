# frozen_string_literal: true
module Praxis
  class FieldExpander
    def self.expand(object, fields = true)
      new.expand(object, fields)
    end

    attr_reader :stack
    attr_reader :history

    def initialize
      @stack = Hash.new do |hash, key|
        hash[key] = Set.new
      end
      @history = Hash.new do |hash, key|
        hash[key] = {}
      end
    end

    def expand(object, fields = true)
      if stack[object].include? fields
        return history[object][fields] if history[object].include? fields
        # We should probably never get here, since we should have a record
        # of the history of an expansion if we're trying to redo it,
        # but we should also be conservative and raise here just in case.
        raise "Circular expansion detected for object #{object.inspect} with fields #{fields.inspect}"
      else
        stack[object] << fields
      end

      result = if object.is_a? Attributor::Attribute
                 expand_type(object.type, fields)
               else
                 expand_type(object, fields)
               end

      result
    ensure
      stack[object].delete fields
    end

    def expand_fields(attributes, fields)
      raise ArgumentError, 'expand_fields must be given a block' unless block_given?

      unless fields == true
        attributes = attributes.select do |k, _v|
          fields.key?(k)
        end
      end

      attributes.each_with_object({}) do |(name, dumpable), hash|
        sub_fields = case fields
                     when true
                       true
                     when Hash
                       fields[name] || true
                     end
        hash[name] = yield(dumpable, sub_fields)
      end
    end

    def expand_type(object, fields = true)
      unless object.respond_to?(:attributes)
        if object.respond_to?(:member_attribute)
          return expand_type(object.member_attribute.type, fields)
        else
          return true
        end
      end

      # just include the full thing if it has no attributes
      return true if object.attributes.empty?

      # True, expands to the default fieldset for blueprints
      fields = object.default_fieldset if object < Praxis::Blueprint && fields == true

      return history[object][fields] if history[object].include? fields

      history[object][fields] = {}
      result = expand_fields(object.attributes, fields) do |dumpable, sub_fields|
        expand(dumpable.type, sub_fields)
      end
      unless fields == true 
        non_matching = fields.keys - object.attributes.keys
        raise "FieldExpansion error: attribute(s) #{non_matching} do not exist in #{object}" unless non_matching.empty?
      end
      history[object][fields].merge!(result)
    end
  end
end