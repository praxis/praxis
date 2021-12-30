# frozen_string_literal: true

module Praxis::Mapper
  class SelectorGeneratorNode
    attr_reader :select, :model, :resource, :tracks

    def initialize(resource)
      @resource = resource

      @select = Set.new
      @select_star = false
      @tracks = {}
    end

    def add(fields)
      fields.each do |name, field|
        map_property(name, field)
      end
      self
    end

    def map_property(name, fields)
      praxis_compat_model = resource.model && resource.model.respond_to?(:_praxis_associations)
      if resource.properties.key?(name)
        add_property(name, fields)
      elsif praxis_compat_model && resource.model._praxis_associations.key?(name)
        add_association(name, fields)
      else
        add_select(name)
      end
    end

    def add_association(name, fields)
      association = resource.model._praxis_associations.fetch(name) do
        raise "missing association for #{resource} with name #{name}"
      end
      associated_resource = resource.model_map[association[:model]]
      raise "Whoops! could not find a resource associated with model #{association[:model]} (root resource #{resource})" unless associated_resource

      # Add the required columns in this model to make sure the association can be loaded
      association[:local_key_columns].each { |col| add_select(col) }

      node = SelectorGeneratorNode.new(associated_resource)
      unless association[:remote_key_columns].empty?
        # Make sure we add the required columns for this association to the remote model query
        fields = {} if fields == true
        new_fields_as_hash = association[:remote_key_columns].each_with_object({}) do |name, hash|
          hash[name] = true
        end
        fields = fields.merge(new_fields_as_hash)
      end

      node.add(fields) unless fields == true

      merge_track(name, node)
    end

    def add_select(name)
      return @select_star = true if name == :*
      return if @select_star

      @select.add name
    end

    def add_property(name, fields)
      dependencies = resource.properties[name][:dependencies]
      # Always add the underlying association if we're overriding the name...
      praxis_compat_model = resource.model && resource.model.respond_to?(:_praxis_associations)
      add_association(name, fields) if praxis_compat_model && resource.model._praxis_associations.key?(name)
      if dependencies
        dependencies.each do |dependency|
          # To detect recursion, let's allow mapping depending fields to the same name of the property
          # but properly detecting if it's a real association...in which case we've already added it above
          if dependency == name
            add_select(name) unless praxis_compat_model && resource.model._praxis_associations.key?(name)
          else
            apply_dependency(dependency)
          end
        end
      end

      head, *tail = resource.properties[name][:through]
      return if head.nil?

      new_fields = tail.reverse.inject(fields) do |thing, step|
        { step => thing }
      end

      add_association(head, new_fields)
    end

    def apply_dependency(dependency)
      case dependency
      when Symbol
        map_property(dependency, true)
      when String
        head, *tail = dependency.split('.').collect(&:to_sym)
        raise 'String dependencies can not be singular' if tail.nil?

        add_association(head, tail.reverse.inject({}) { |hash, dep| { dep => hash } })
      end
    end

    def merge_track(track_name, node)
      raise "Cannot merge another node for association #{track_name}: incompatible model" unless node.model == model

      existing = tracks[track_name]
      if existing
        node.select.each do |col_name|
          existing.add_select(col_name)
        end
        node.tracks.each do |name, n|
          existing.merge_track(name, n)
        end
      else
        tracks[track_name] = node
      end
    end

    def dump
      hash = {}
      hash[:model] = resource.model
      if !@select.empty? || @select_star
        hash[:columns] = @select_star ? [:*] : @select.to_a
      end
      hash[:tracks] = @tracks.each_with_object({}) { |(name, node), hash| hash[name] = node.dump } unless @tracks.empty?
      hash
    end
  end

  # Generates a set of selectors given a resource and
  # list of resource attributes.
  class SelectorGenerator
    # Entry point
    def add(resource, fields)
      @root = SelectorGeneratorNode.new(resource)
      @root.add(fields)
      self
    end

    def selectors
      @root
    end
  end
end
