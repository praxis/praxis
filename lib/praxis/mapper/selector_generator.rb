module Praxis::Mapper
  # Generates a set of selectors given a resource and
  # list of resource attributes.
  class SelectorGenerator
    attr_reader :selectors

    def initialize
      @selectors = Hash.new do |hash, key|
        hash[key] = {select: Set.new, track: Set.new}
      end
      @seen = Hash.new do |hash, resource|
        hash[resource] = Set.new
      end
    end

    def add(resource, fields)
      return if @seen[resource].include? fields
      @seen[resource] << fields

      fields.each do |name, field|
        map_property(resource, name, field)
      end
    end

    def select_all(resource)
      selectors[resource.model][:select] = true
    end

    def map_property(resource, name, fields)
      if resource.properties.key?(name)
        add_property(resource, name, fields)
      elsif resource.model._praxis_associations.key?(name)
        add_association(resource, name, fields)
      else
        add_select(resource, name)
      end
    end

    def add_select(resource, name)
      return select_all(resource) if name == :*
      return if selectors[resource.model][:select] == true

      selectors[resource.model][:select] << name
    end

    def add_track(resource, name)
      selectors[resource.model][:track] << name
    end

    def add_association(resource, name, fields)
      association = resource.model._praxis_associations.fetch(name) do
        raise "missing association for #{resource} with name #{name}"
      end
      associated_resource = resource.model_map[association[:model]]

      case association[:type]
      when :many_to_one
        add_track(resource, name)
        Array(association[:key]).each do |akey|
          add_select(resource, akey)
        end
      when :one_to_many
        add_track(resource, name)
        Array(association[:key]).each do |akey|
          add_select(associated_resource, akey)
        end
      when :many_to_many
        # If we haven't explicitly added the "through" option in the association
        # then we'll assume the underlying ORM is able to fill in the gap. We will
        # simply add the fields for the associated resource below
        if association.key? :through
          head, *tail = association[:through]
          new_fields = tail.reverse.inject(fields) do |thing, step|
            {step => thing}
          end
          return add_association(resource, head, new_fields)
        else
          add_track(resource, name)
        end
      else
        raise "no select applicable for #{association[:type].inspect}"
      end

      unless fields == true
        # recurse into the field
        add(associated_resource,fields)
      end
    end

    def add_property(resource, name, fields)
      dependencies = resource.properties[name][:dependencies]
      if dependencies
        dependencies.each do |dependency|
          # if dependency includes the name, then map it directly as the field
          if dependency == name
            add_select(resource, name)
          else
            apply_dependency(resource, dependency)
          end
        end
      end

      head, *tail = resource.properties[name][:through]
      return if head.nil?

      new_fields = tail.reverse.inject(fields) do |thing, step|
        {step => thing}
      end

      add_association(resource, head, new_fields)
    end

    def apply_dependency(resource, dependency)
      case dependency
      when Symbol
        map_property(resource, dependency, {})
      when String
        head, tail = dependency.split('.').collect(&:to_sym)
        raise "String dependencies can not be singular" if tail.nil?

        add_association(resource, head, {tail => true})
      end
    end

  end
end
