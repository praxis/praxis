# FOR AR < 6.1
module ActiveRecord
  PRAXIS_JOIN_ALIAS_PREFIX = Praxis::Extensions::AttributeFiltering::ALIAS_TABLE_PREFIX
  class Relation
    def construct_join_dependency(associations, join_type) # :nodoc:
      # Praxis: inject references into the join dependency
      ActiveRecord::Associations::JoinDependency.new(
        klass, table, associations, join_type, references: references_values
      )
    end
  end

  module Associations
    class JoinDependency
      attr_accessor :references

      private
      def initialize(base, table, associations, join_type, references: nil)
        tree = self.class.make_tree associations
        @references = references # Save the references values into the instance (to use during build)
        built = build(tree, base)

        @join_root = JoinBase.new(base, table, built)
        @join_type = join_type
      end

      # Praxis: table aliases for is shared for 5x and 6.0
      def table_aliases_for(parent, node)
        last_reflection, *rest = node.reflection.chain
        
        last_table = alias_tracker.aliased_table_for(
          last_reflection.table_name,
          table_alias_for(last_reflection, parent, last_reflection != node.reflection),
          last_reflection.klass.type_caster
        )
        # Praxis: Alias a joined table IF it "path" is in the list of references (i.e., explicitly requested)
        if node.alias_path
          last_table = last_table.left if last_table.is_a?(Arel::Nodes::TableAlias) #un-alias it if necessary
          last_table = last_table.alias(node.alias_path.join('/')) 
        end

        # through tables do not need aliasing
        rest_tables = rest.map { |reflection|
          type_caster = reflection.klass.type_caster
          Arel::Table.new(reflection.table_name, type_caster: type_caster)
        }
        [last_table, *rest_tables ]
      end

      # Praxis: build for is shared for 5x and 6.0
      def build(associations, base_klass, path: [PRAXIS_JOIN_ALIAS_PREFIX])
        associations.map do |name, right|
          reflection = find_reflection base_klass, name
          reflection.check_validity!
          reflection.check_eager_loadable!

          if reflection.polymorphic?
            raise EagerLoadPolymorphicError.new(reflection)
          end
          # Praxis: set an alias_path in the JoinAssociation if its path matches a requested reference
          child_path = (path && !path.empty?) ? path + [name] : nil
          association = JoinAssociation.new(reflection, build(right, reflection.klass, path: child_path))
          association.alias_path = child_path if references.include?(child_path.join('/'))
          association            
        end
      end

    end
    class ActiveRecord::Associations::JoinDependency::JoinAssociation
      attr_accessor :alias_path
    end
  end
end