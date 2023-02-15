# frozen_string_literal: true

module Praxis
  module Mapper
    class SelectorGeneratorNode
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
        attr_reader :deps
        def initialize(name:)
          @name = name
          @fields = Hash.new do |hash, key|
            hash[key] = FieldDependenciesNode.new(name: key)
          end
          @deps = Set.new
          # We could translate the path to the actual pointer to the fields hash object but then the 'pop' is a bit more difficult
          # OR maybe we leave it like that, but we also have the direct pointer of the current field for lookups
          @current_field = []
        end

        def start_field(field_name)
          @current_field.push field_name
        end

        def end_field
          @current_field.pop
        end

        def add_local_dep(name)
          pointer = @current_field.empty? ? @fields[true] : @fields.dig(*@current_field)
          pointer.deps.add name
        end

        def [](*path)
          @fields.dig(*path)
        end

        # For spec/debugging purposes only
        def dump
          hash = {}
          hash[true] = @deps.to_a unless @deps.empty?
          @fields.each_with_object(hash) do |(name,node), h|
            dumped = node.dump
            h[name] = dumped unless dumped.empty?
          end
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

        @fields_node.add_local_dep(name)
        @select.add name
      end

      def add_property(name, fields)
        dependencies = resource.properties[name][:dependencies]
        # Always add the underlying association if we're overriding the name...
        if (praxis_compat_model = resource.model&.respond_to?(:_praxis_associations))
          aliased_as = resource.properties[name][:as]
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
        end
        dependencies&.each do |dependency|
          # To detect recursion, let's allow mapping depending fields to the same name of the property
          # but properly detecting if it's a real association...in which case we've already added it above
          if dependency == name
            add_select(name) unless praxis_compat_model && resource.model._praxis_associations.key?(name)
          else
            apply_dependency(dependency)
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
        hash[:tracks] = @tracks.transform_values(&:dump) unless @tracks.empty?
        hash[:fields] = @fields_node.dump
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