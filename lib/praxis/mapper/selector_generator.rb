# frozen_string_literal: true

module Praxis
  module Mapper
    class SelectorGeneratorNode
      attr_reader :select, :model, :resource, :tracks, :field_deps

      class DepNode
        attr_reader :parent, :name, :deps

        def initialize(name: nil, parent: nil)
          @name = name
          @parent = parent
          @fields = {}
          @deps = Set.new
        end

        def add_field(name)
          @fields[name] = DepNode.new(name: name, parent: self)
          @fields[name]
        end

        def add_dep(dep_name)
          @deps.add dep_name
        end
        
        def dump
          h = { _subtree_deps: @deps.to_a }
          @fields.each do |name, node|
            h[name] = node.dump
          end
          h
        end

        def rollup
          return if @fields.empty?

          @fields.each do |_name, node|
            node.rollup
            @deps.merge(node.deps)
          end
        end
      end

      def initialize(resource)
        @resource = resource

        @select = Set.new
        @select_star = false
        @tracks = {}
        @field_node = DepNode.new
        # @field_deps = Hash.new do |hash, key| 
        #   if key == :_subtree_deps
        #     hash[key] = Set.new
        #   else
        #     hash[key] = Hash.new do |hash, key|
        #       if key == :_subtree_deps
        #         hash[key] = Set.new
        #       else
        #         hash[key] = Hash.new do |hash, key|
        #           if key == :_subtree_deps
        #             hash[key] = Set.new
        #           else
        #             hash[key] = Hash.new do |hash, key|
        #               if key == :_subtree_deps
        #                 hash[key] = Set.new
        #               else
        #                 hash[key] = Hash.new  { |hash, key| hash[key] = Hash.new }
        #               end
        #             end
        #           end
        #         end
        #       end
        #     end
        #   end
        # end
        @mapping_property = [] # Current top level property mapped in this node
      end

      def rollup_deps
        @field_node.rollup
      end

      def add(fields)
        fields.each do |name, field|
          @field_node = @field_node.add_field(name)
          map_property(name, field)
          @field_node = @field_node.parent if @field_node.parent
        end
        self
      end

      def map_property(name, fields)
        praxis_compat_model = resource.model&.respond_to?(:_praxis_associations)
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
          new_fields_as_hash = association[:remote_key_columns].each_with_object({}) do |key, hash|
            hash[key] = true
          end
          fields = fields.merge(new_fields_as_hash)
        end

        node.add(fields) unless fields == true

        merge_track(name, node)
      end

      def add_select(name)
        return @select_star = true if name == :*
        return if @select_star

        puts "ADDING SELECT: #{@mapping_property.join('/')} -> #{name}"
        @field_node.add_dep(name)
        # @field_deps.dig(*@mapping_property)[:_subtree_deps] ||= Set.new
        # @field_deps.dig(*@mapping_property)[:_subtree_deps].add(name)
        @select.add name
      end

      def add_property(name, fields)
        puts "ADDING PROP: #{@mapping_property.join('/')} -> #{name}"
        @field_node.add_dep(name)
        # @field_deps.dig(*@mapping_property)[:_subtree_deps] ||= Set.new
        # @field_deps.dig(*@mapping_property)[:_subtree_deps].add(name)
        # Here "name" IS a property, and hopefully we've only sent it here if it matches the field name??
        # NO...if it comes from the initial add, yes, cause it loops over fields...
        # If it coms from apply dependency...hmmm
        # puts "ADDING PROPERTY DEP: #{@mapping_property.join('/')} -> #{name} (fields: #{fields})"
        puts "YES!!! SAVE: #{@mapping_property.join('/')}" if @mapping_property.last == name
        # ...but what do we save? ... 'true?' ... the list of deps? ...
        # @field_deps.dig(*@mapping_property)[name] = true
        dependencies = resource.properties[name][:dependencies]
        # Always add the underlying association if we're overriding the name...
        if (praxis_compat_model = resource.model&.respond_to?(:_praxis_associations))
          aliased_as = resource.properties[name][:as]
          if aliased_as == :self
            # Special keyword to add itself as the association, but still continue procesing the fields
            # This is useful when we expose resource fields tucked inside another sub-struct, this way
            # we can make sure that if the fields necessary to compute things inside the struct, they are preloaded
            copy = @field_node
            add(fields)
            @field_node = copy # restore the currently mapped property, cause 'add' will null it
          else
            first, *rest = aliased_as.to_s.split('.').map(&:to_sym)

            extended_fields = \
              if rest.empty?
                fields
              else
                rest.reverse.inject(fields) do |accum, prop|
                  { prop => accum }
                end
              end
            add_association(first, extended_fields) if resource.model._praxis_associations[first]
          end
        end
        dependencies&.each do |dependency|
          # To detect recursion, let's allow mapping depending fields to the same name of the property
          # but properly detecting if it's a real association...in which case we've already added it above
          if dependency == name
            add_select(name) unless praxis_compat_model && resource.model._praxis_associations.key?(name)
          else
            if fields.is_a?(Hash) && fields[dependency]
              # We know this dependency matches a field ... so set it in the path in case it ends up
              # being a property
              @field_node = @field_node.add_field(dependency)
              apply_dependency(dependency, fields[dependency])
              @field_node = @field_node.parent  # restore the currently mapped property, cause 'add' will null it
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

      def apply_dependency(dependency, fields=true)
        case dependency
        when Symbol
          map_property(dependency, fields)
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
        hash[:field_deps] = @field_node.dump
        if !@select.empty? || @select_star
          hash[:columns] = @select_star ? [:*] : @select.to_a
        end
        hash[:tracks] = @tracks.transform_values(&:dump) unless @tracks.empty?
        hash
      end
    end

    # Generates a set of selectors given a resource and
    # list of resource attributes.
    class SelectorGenerator
      attr_reader :root

      # Entry point
      def add(resource, fields)
        @root = SelectorGeneratorNode.new(resource)
        @root.add(fields)
        @root.rollup_deps
        self
      end

      def selectors
        @root
      end
    end
  end
end
