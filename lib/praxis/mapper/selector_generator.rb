# frozen_string_literal: true

module Praxis
  module Mapper
    class SelectorGeneratorNode
      attr_reader :select, :model, :resource, :tracks, :field_node
      

      class FieldDependenciesNode
        attr_reader :parent, :name, :deps, :fields, :stack
        attr_accessor :is_an_as

        def initialize(name: nil, parent: nil)
          @name = name
          @parent = parent
          @fields = {}
          @deps = Set.new

          @stack = []
          # puts "CREATED NODE: #{self.path_name}"
          @is_an_as = false
        end

        def path_name
          return name if parent.nil?
          "#{parent.path_name}.#{name}"
        end

        def add_field(name)
          # puts "#{self.path_name} ADDING FIELD: #{name}"
          @fields[name] = FieldDependenciesNode.new(name: name, parent: self)
        end

        def push_chain_assoc(assoc_name)
          puts "#{self.path_name} FOLLOW ASSOC: #{assoc_name} for node: #{self.name}"
          @stack.push assoc_name
        end

        def unfollow_assoc(assoc_name)
          puts "#{self.path_name} UNFOLLOW ASSOC: #{assoc_name} for node: #{self.name}"
          last = @stack.pop assoc_name
          raise 'BAD!' unless last == assoc_name
        end

        def add_dep(dep_name)
          puts "#{self.path_name} ADDING DEP: #{dep_name} for node: #{self.name}"
          @deps.add dep_name
        end

        # For spec/debugging purposes only
        def dump
          if @fields.empty? # leaf node
            @deps.to_a
          else
            @fields.each_with_object({}) do |(name,node), h|
              dumped = node.dump
              h[name] = dumped unless dumped.empty?
            end
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

      def add(fields)
        puts "ADD: ############################### for #{resource} adding #{fields}"
        fields.each do |name, field|
          add_field(name, field)
        end
        puts "DONE ADD: ########################## for #{resource} with #{fields}"
        self
      end

      def add_field(fieldname, subfields)
        @field_node = @field_node.add_field(fieldname)
        puts "START ADDING FIELD #{fieldname} => #{subfields}"
        map_property(fieldname, subfields)
        puts "DONE ADDING FIELD #{fieldname} => #{subfields}"
        # TODO: Maybe rollup and or compact to the parent, depending on what the state/type of the field we just added?
        # require 'pry'
        # binding.pry
        @field_node = @field_node.parent if @field_node.parent
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
# require 'pry'
# binding.pry
        # In here we have the field node from the node (inner) object, and we have the field node from this SelectoGenerator (field_node)
        # We need to properly merge/rollup things.
        # if field_node.is_an_as rollup the stack from the node.field_node
        # mark it in the currently processed field...
        if field_node.is_an_as
          puts ">>>>>>>>>>> SETTING: FIELD #{field_node.name} to follow tracks: #{field_node.stack}->#{node.field_node.stack}"
          node.field_node
        end
        merge_track(name, node)
      end

      def add_select(name)
        return @select_star = true if name == :*
        return if @select_star

        # NOTE: Not sure if we need to add methods that aren't properties (commenting line below)
        # If we do that, the lists are smaller, but what if there are methods that we want to detect that do not have a property?
        @field_node.add_dep(name)
        puts "     --> SELECT #{name} for current field"
        @select.add name
      end

      # def follow_until_not_as(components)
      #   i = 0
      #   final = nil
      #   loop do
      #     if components.size == 1

      #     end
      #     assoc = resource.model._praxis_associations[components[i]]
      #     last_res = follow_until_not_as(components[i+1..-1])
          
      #     i += 1
      #   end
      #   last_res
      # end

      # We know name is a property...
      def add_property(name, fields)
        puts "Adding PROPERTY: #{name} with FIELDS: #{fields}"
        @field_node.add_dep(name)
        # @field_node.add_dep(name) if fields == true # Only add dependencies for leaves
        dependencies = resource.properties[name][:dependencies]
        # Always add the underlying association if we're overriding the name...
        if (praxis_compat_model = resource.model&.respond_to?(:_praxis_associations))
          aliased_as = resource.properties[name][:as]
          if aliased_as
            puts "PROPERTY with AS! #{name} -> #{aliased_as}"
            @field_node.is_an_as = true
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
              # require 'pry'
              # binding.pry
              if resource.model._praxis_associations[first]
                puts "Following assoc for: #{first} with FIELDS: #{extended_fields}"
                @field_node.push_chain_assoc(first)
                # require 'pry'
                # binding.pry
                add_association(first, extended_fields)
                require 'pry'
                binding.pry
                puts 'asdfa'
              end
              # @field_node.unfollow_assoc(first)
            end
            puts "PROPERTY with AS (END)! #{name} -> #{aliased_as}"
            # NOTE: This skips potentially the 'through' association bits below, refactor to have that into account
            return
          elsif resource.model._praxis_associations[name]
            require 'pry'
            binding.pry
            # Not aliased ... but if there is an existing association for the propety name, we add it
            add_association(name, fields)
            # NOTE: This skips potentially the 'through' association bits below, refactor to have that into account
            return
          end
        end
        # If we have a property group, and the subfields want to selectively restrict what to depend on
        if fields != true && resource.property_groups[name]
          # Prepend the group name to fields if it's an inner hash
          prefixed_fields = fields == true ? {} : fields.keys.each_with_object({}) {|k,h| h["#{name}_#{k}".to_sym] = k }
          # Try to match all inner fields
          prefixed_fields.each do |prefixedname, origfieldname|
            next unless dependencies.include?(prefixedname)

            @field_node = @field_node.add_field(origfieldname) # Mark it as orig name
            apply_dependency(prefixedname, fields[origfieldname])
            @field_node = @field_node.parent # restore the parent node since we're done with the sub field
          end
        else # not a property group: process all dependencies
          dependencies&.each do |dependency|
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
        self
      end

      def selectors
        @root
      end
    end
  end
end
