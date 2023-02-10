# frozen_string_literal: true

module Praxis
  module Mapper
    class SelectorGeneratorNode
      attr_reader :select, :model, :resource, :tracks, :field_node

      class FieldDependenciesNode
        attr_reader :parent, :name, :deps, :fields

        def initialize(name: nil, parent: nil)
          @name = name
          @parent = parent
          @fields = {}
          @deps = Set.new
        end

        def path_name
          return name if parent.nil?
          "#{parent.path_name}.#{name}"
        end

        def add_field(name)
          @fields[name] = FieldDependenciesNode.new(name: name, parent: self)
        end

        def add_dep(dep_name)
          @deps.add dep_name
        end

        def dump
          if @fields.empty? #leaf node
            @deps.to_a
          else
            @fields.each_with_object({}) do |(name,node), h|
              dumped = node.dump
              h[name] = dumped unless dumped.empty?
            end
          end
          # h = @deps.empty? ? {} : { _subtree_deps: @deps.to_a }
          # @fields.each do |name, node|
          #   h[name] = node.dump
          # end
          # h
        end

        def rollup
          return if @fields.empty?

          @fields.each do |_name, node|
            # Force rollup downstream
            node.rollup
            # No need to rollup to the root node (there no field for the 'top')
            @deps.merge(node.deps) unless parent.nil?
          end
        end
      end

      def initialize(resource)
        @resource = resource

        @select = Set.new
        @select_star = false
        @tracks = {}
        @field_node = FieldDependenciesNode.new
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
        puts "PROP #{name} -> FIELDS: #{fields == true ? 'ALL' : fields.keys}"
        # require 'pry'
        # binding.pry
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

        # NOTE: Not sure if we need to add methods that aren't properties (commenting line below)
        # If we do that, the lists are smaller, but what if there are methods that we want to detect that do not have a property?
        @field_node.add_dep(name)
        @select.add name
      end

      def add_property(name, fields)
        @field_node.add_dep(name) if fields == true # Only add dependencies for leaves
        dependencies = resource.properties[name][:dependencies]
        property_processed = false
        # Always add the underlying association if we're overriding the name...
        if (praxis_compat_model = resource.model&.respond_to?(:_praxis_associations))
          aliased_as = resource.properties[name][:as]
          if aliased_as
            if aliased_as == :self
              # Special keyword to add itself as the association, but still continue procesing the fields
              # This is useful when we expose resource fields tucked inside another sub-struct, this way
              # we can make sure that if the fields necessary to compute things inside the struct, they are preloaded
              copy = @field_node
              add(fields)
              @field_node = copy # restore the currently mapped property, cause 'add' will null it
              property_processed = true
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
              if resource.model._praxis_associations[first]
                add_association(first, extended_fields) 
                property_processed = true
              end
            end
          else
            # Not aliased ... but if there is an existing association for the propety name, we add it
            if resource.model._praxis_associations[name]
              add_association(name, fields) 
              property_processed = false
            end
          end
        end
        is_within_a_property_group = fields != true #resource.property_groups[name]
        prefixed_fields = \
          if fields == true
            {}
          else
            fields.keys.each_with_object({}) do |k,h|
              h["#{name}_#{k}".to_sym] = k # Prepend the group name to fields
            end
          end
        unless property_processed
          #If it was an "as" association and we processed, we're gonna ignore the dependencies as they should have
          # been processed within the context of the association
          matched_fields = []
          matched_deps = []
          dependencies&.each do |dependency|
            # To detect recursion, let's allow mapping depending fields to the same name of the property
            # but properly detecting if it's a real association...in which case we've already added it above
            if dependency == name
              add_select(name) unless praxis_compat_model && resource.model._praxis_associations.key?(name)
            else
              if fields.is_a?(Hash)
                # Let's try to match the prefixed one first (we don't want to pickup the direct name one, if there's a prefixed setup for it)
                if is_within_a_property_group && prefixed_fields.keys.include?(dependency)
                  dep_matches_field = true
                  sub_field_name = prefixed_fields[dependency]
                  matched_fields.push(sub_field_name)
                  matched_deps.push(dependency)
                elsif fields[dependency]
                  # We could match an existing property without the prefix...but that might be weird if it
                  # actually exists in the parent...maybe it is fine...? but need to think about it.
                  dep_matches_field = true
                  sub_field_name = dependency
                  matched_fields.push(sub_field_name)
                  matched_deps.push(dependency)
                else
                  dep_matches_field = false
                end
                # dep_matches_field = (fields != true) && (fields[dependency] || (is_within_a_property_group && prefixed_fields.keys.include?(dependency)))
                if dep_matches_field
                  # We know this dependency matches a field ... so set it in the path in case it ends up
                  # being a property
                  @field_node = @field_node.add_field(sub_field_name) # Mark it as orig name
                  apply_dependency(dependency, fields[sub_field_name])
                  @field_node = @field_node.parent # restore the parent node since we're done with the sub field
                else
                  # Don't even bother adding the dependency if this is a subhash, and there's no match for it (conditional dependency)
                end
              else
                apply_dependency(dependency)
              end
            end
          end
          if dependencies && fields.is_a?(Hash) && fields.size > matched_fields.size
            puts "Discarded all dependencies cause no matching prefixed properties!!!! (FIELDS: #{fields.keys}) -> MATCHED: #{matched_fields}" 
            # NOTE: We could add a field to enable/raise when this happens...this will make sure all props are processed when
            # not all of the subfields are matched
            begin
              (dependencies - matched_deps).each do |dep|
                apply_dependency(dep)
              end
            rescue => e
              require 'pry'
              binding.pry
              puts 'asdfa'
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

          add_association(head, tail.reverse.inject(true) { |hash, dep| { dep => hash } })
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
        # @root.rollup_deps
        # require 'pry'
        # binding.pry
        self
      end

      def selectors
        @root
      end
    end
  end
end
