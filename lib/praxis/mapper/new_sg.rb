# frozen_string_literal: true

module Praxis
  module Mapper
    module SelectorGeneratorNodeDebugger
      def add(fields)
        puts "ADD fields: #{fields}"
        super
      end
      def map_property(name, fields, **args)
        puts "MAP PROP #{name} fields: #{fields} (args: #{args})"
        super
      end
      def add_association(name, fields, **args)
        puts "ADD ASSOCIATION #{name} fields: #{fields} (args: #{args})"
        super
      end
      def add_select(name, add_field: true)
        puts "ADD SELECT #{name} (add field: #{add_field})"
        super
      end
      def add_fwding_property(name, fields)
        puts "ADD FWD ASSOC #{name} fields: #{fields}"
        super
      end
      def add_property(name, fields)
        puts "ADD PROP #{name} fields: #{fields}"
        super
      end
      def apply_dependency(dependency, fields=true)
        puts "APPLY DEP #{dependency} fields: #{fields}"
        super
      end
    end
    class SelectorGeneratorNode
      prepend SelectorGeneratorNodeDebugger
      attr_reader :select, :model, :resource, :tracks, :fields_node

      # FieldDependenciesNode, attached to a SelectorGeneratorNode, which will contain, for every field passed in (not properties, but fields), the
      # list of property dependencies associated with them.
      # If these property dependenceis are for the 'local' resource of the SelectorGeneratorNode, they'd be just an array of property names
      # If a field is a property that is an association to another resource, the dependency will indicate which 'track' it depends on
      # and any further resolution of dependencies from fields need to be continued in that track's SelectorGenerator's FieldDependenciesNode (recursively)
      # Note on 'true' values (which could potentially have subfields if they had been expanded): TODO
      
      # NOTE: local => should be 'true' to denote that, and it will never clash with other field names...
      # Usage from bulk calculator of this structure will be like
      # results = processor.find_bulk_loadable_attributes(processor.root_node, expanded_fields, resource_rows)
      # So, given a root SG node ... and a set of expanded fields ... we need to get:
      # result = processor.find_bulk_loadable_attributes(processor.field_node, fields, data)
      # For keys
      # expect(result.keys).to match_array([
      #   [Im::V1::Resources::Contact, :last_emailed],
      #   [Im::V1::Resources::Contact, :total_committed_amount], 
      #   [Im::V1::Resources::Contact, :total_contributed_amount]
      # ])
      # And each of these keys will have a set of ids
      # Also, we need to give references to a given SG when there are :as association aliases...we cannot do it by just the name of the :tracks
      # because they can be nested
      # fields: {
      #   columnname: { local: [columnname]} # A field which directly maps to a column name
      #   aliasedcolumnname: { local: [aliasedcolumnname columnname]} # A field which has a single property pointing to a column name
      #   methodname: { local: [methodname columnname otherproperty]} # A method that requires calling the columnname and another property method to calculate
      #   complexmethodname: { local: [complexmethodname columnname directassociation]} # method requires a column and calling an association to calculate
      #   complexmethodname2: { local: [complexmethodname2 columnname property_depending_from_assocs ...dependent_asocs?]} # method requires a column and calling an association to calculate
      #   complexmethodname3: { local: [complexmethodname3 columnname aliasedassociation_as]} # method requires a column and calling an aliased :as association to calculate ????

      #   direct_as_association: { ref: SGNode? } # If self, it will be its own SGNode
      #   struct: { local: [unrolled props from struct property]}
      #   struct_with_assoc: { local: [unrolled props from struct property ... how do we map the assoc here? I guess we need to simply join it...no fields!]}
      #   struct_with_an_as_assoc: { local: [unrolled props from struct property ... how do we map the assoc here? I guess we need to simply join it...no fields!]}
      #   propgroup: {
      #     local: []???
      #     subfield1: inner_node => { fields { ....}}
      #     subfield2: inner_node => { fields { ....}}
      #   }
      # }

      class FieldDependenciesNode
        attr_reader :deps, :fields
        attr_accessor :references

        def initialize(name:)
          @name = name
          @fields = Hash.new do |hash, key|
            hash[key] = FieldDependenciesNode.new(name: key)
          end
          @deps = Set.new
          @references = nil
          # We could translate the path to the actual pointer to the fields hash object but then the 'pop' is a bit more difficult
          # OR maybe we leave it like that, but we also have the direct pointer of the current field for lookups
          @current_field = []
        end

        def start_field(field_name)
          puts "    >>> STARTING FIELD: #{field_name}"
          @current_field.push field_name
        end

        def end_field
          puts "    <<<  ENDING FIELD: #{@current_field.last}"
          @current_field.pop
        end

        def add_local_dep(name)
          #return if name == @current_field.last # We know, that a given field would depend on a property of the same name, so no need to add it
          pointer = @current_field.empty? ? @fields[true] : @fields.dig(*@current_field)
          pointer.deps.add name
        end

        # This should be a single thing no? i.e., set_reference ... instead of an array...
        def set_reference(selector_node)
          puts "Setting reference for #{@current_field} to #{selector_node}"
          pointer = @current_field.empty? ? @fields[true] : @fields.dig(*@current_field)
          pointer.references = selector_node
        end

        def dig(...)
          @fields.dig(...)
        end
        def [](*path)
          @fields.dig(*path)
        end

        # For spec/debugging purposes only
        def dump
          hash = {}
          hash[:deps] = @deps.to_a unless @deps.empty?
          unless @references.nil?
            hash[:references] = "Linked to resource: #{@references.resource}"
          end
          field_deps = @fields.each_with_object({}) do |(name,node), h|
            dumped = node.dump
            h[name] = dumped unless dumped.empty?
          end
          hash[:fields] = field_deps unless field_deps.empty?
          hash
        end
      end

      def initialize(resource)
        @resource = resource

        @select = Set.new
        @select_star = false
        @fields_node = FieldDependenciesNode.new(name: '/')
        @tracks = {}
      end

      def add(fields)
        fields.each do |name, field|
          fields_node.start_field(name)
          map_property(name, field)
          fields_node.end_field
        end
        self
      end

      def map_property(name, fields, as_dependency: false)
        praxis_compat_model = resource.model&.respond_to?(:_praxis_associations)
        if resource.properties.key?(name)
          if (target = resource.properties[name][:as])
            leaf_node = add_fwding_property(name, fields)
            fields_node.set_reference(leaf_node) unless target == :self
          else
            add_property(name, fields)
          end
          fields_node.add_local_dep(name)
        elsif praxis_compat_model && resource.model._praxis_associations.key?(name)
          add_association(name, fields)
          # Single association properties are also pointing to the corresponding tracked SelectorGeneratorNode
          # but only if they are implicit properties, without dependencies
          if as_dependency
            fields_node.add_local_dep(name)
          else
            fields_node.set_reference(tracks[name]) 
          end
        else
          add_select(name)
        end
      end

      def add_string_association(names_array)
        puts "**************SWITCHING TO STRING ASSOCIATION: #{names_array} *****************"
        first, *rest = names_array

        association = resource.model._praxis_associations.fetch(first) do
          raise "missing association for #{resource} with name #{first}"
        end
        associated_resource = resource.model_map[association[:model]]
        raise "Whoops! could not find a resource associated with model #{association[:model]} (root resource #{resource})" unless associated_resource

        # Add the required columns in this model to make sure the association can be loaded
        association[:local_key_columns].each { |col| add_select(col, add_field: false) }

        node = SelectorGeneratorNode.new(associated_resource)
        unless association[:remote_key_columns].empty?
          # Make sure we add the required columns for this association to the remote model query
          fields = {}
          new_fields_as_hash = association[:remote_key_columns].each_with_object({}) do |key, hash|
            hash[key] = true
          end
          fields = fields.merge(new_fields_as_hash)
        end

        node.add(fields) unless fields == true
        leaf_node = rest.empty? ? nil : node.add_string_association(rest)
        merge_track(first, node)
        puts "------------------ENDING ASSOCIATION: #{first} ---NODE: #{tracks[first]}------"
        leaf_node || node # Return the leaf (i.e., us, if we're the last component or the result of the string_association if there was one)
      end

      def add_association(name, fields)
        puts "**************SWITCHING TO ASSOCIATION: #{name} ******** FIELDS #{fields}*********"
        #fields_node.retrieve_last_of_chain = true
        association = resource.model._praxis_associations.fetch(name) do
          raise "missing association for #{resource} with name #{name}"
        end
        associated_resource = resource.model_map[association[:model]]
        raise "Whoops! could not find a resource associated with model #{association[:model]} (root resource #{resource})" unless associated_resource

        # Add the required columns in this model to make sure the association can be loaded
        association[:local_key_columns].each { |col| add_select(col, add_field: false) }

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
        puts "------------------ENDING ASSOCIATION: #{name} ---NODE: #{tracks[name]}------"
        node
      end

      def add_select(name, add_field: true)
        return @select_star = true if name == :*
        return if @select_star

        # Do not add a field dependency, if we know we're just adding a Local/FK constraint
        @fields_node.add_local_dep(name) if add_field 
        @select.add name
      end

      def add_fwding_property(name, fields)
        aliased_as = resource.properties[name][:as]
        if aliased_as == :self
          # Special keyword to add itself as the association, but still continue procesing the fields
          # This is useful when we expose resource fields tucked inside another sub-struct, this way
          # we can make sure that if the fields necessary to compute things inside the struct, they are preloaded
          add(fields) unless fields == true
        else
          # Assumes (as: option of the property DSL should check check) that all forwarded properties need to be pure associations
          # We know we've now added the chain of association dependencies under our node...so we'll start getting the 'first' of them
          # and recurse down the node until the leaf.
          # Then, we need to apply the incoming fields to that.
          leaf_node = add_string_association(aliased_as.to_s.split('.').map(&:to_sym))
          leaf_node.add(fields) unless fields == true # If true, no fields to apply
          leaf_node
        end
      end

      def add_property(name, fields)
        dependencies = resource.properties[name][:dependencies]
        # Always add the underlying association if we're overriding the name...
        if (praxis_compat_model = resource.model&.respond_to?(:_praxis_associations))
          aliased_as = resource.properties[name][:as]
          if aliased_as
            if aliased_as == :self
              # Special keyword to add itself as the association, but still continue procesing the fields
              # This is useful when we expose resource fields tucked inside another sub-struct, this way
              # we can make sure that if the fields necessary to compute things inside the struct, they are preloaded
              add(fields)
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
          elsif resource.model._praxis_associations[name]
            # Not aliased ... but if there is an existing association for the propety name, we add it (and ignore any deps in place)
            add_association(name, fields)
          end
        end
        # If we have a property group, and the subfields want to selectively restrict what to depend on
        if fields != true && resource.property_groups[name]
          puts ">>>>>>>>>>>>>>>>FOUND A PROPERTY GROUP for #{name}"
          # Prepend the group name to fields if it's an inner hash
          prefixed_fields = fields == true ? {} : fields.keys.each_with_object({}) {|k,h| h["#{name}_#{k}".to_sym] = k }
          # Try to match all inner fields
          prefixed_fields.each do |prefixedname, origfieldname|
            next unless dependencies.include?(prefixedname)

            fields_node.start_field(origfieldname) # Mark it as orig name
            apply_dependency(prefixedname, fields[origfieldname])
            fields_node.end_field
          end
        else
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
      end

      def apply_dependency(dependency, fields=true)
        case dependency
        when Symbol
          map_property(dependency, fields, as_dependency: true)
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

      # Debugging method for rspec, to easily match the desired output
      # By default it only outputs the info related to computing columns and track dependencies.
      # Overriding the mode will allow to dump the model and only the field dependencies
      def dump(mode: :columns_and_tracks)
        hash = {}
        hash[:model] = resource.model
        if mode == :columns_and_tracks
          if !@select.empty? || @select_star
            hash[:columns] = @select_star ? [:*] : @select.to_a
          end
        elsif mode == :fields
          dumped_fields_node = @fields_node.dump
          raise "Fields node has more keys than fields!! #{dumped_fields_node}" if dumped_fields_node.keys.size > 1
          hash[:fields] = dumped_fields_node[:fields] if dumped_fields_node[:fields]
        else
          raise "Unknown mode #{mode} for dumping SelectorGenerator"
        end
        hash[:tracks] = @tracks.transform_values {|v| v.dump(mode: mode)} unless @tracks.empty?
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
end
