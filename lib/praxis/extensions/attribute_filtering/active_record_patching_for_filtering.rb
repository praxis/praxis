require 'active_record'

      # FOR AR < 6.1

module ActiveRecord
  class Relation
    def construct_join_dependency(associations, join_type) # :nodoc:
      ActiveRecord::Associations::JoinDependency.new(
        klass, table, associations, join_type, references: references_values
      )
    end
  end
  module Associations
    class JoinDependency
      attr_accessor :references
      private
      def table_aliases_for(parent, node)
        accum_path = parent.is_a?(JoinAssociation) ? parent.alias_path : ['joins:']
        last_reflection, *rest = node.reflection.chain
        
        last_table = Arel::Table.new(last_reflection.table_name, type_caster: last_reflection.klass.type_caster)
        last_table = last_table.alias(node.alias_path.join('/')) if node.alias_path

        # through tables do not need aliasing
        rest_tables = rest.map { |reflection|
          type_caster = reflection.klass.type_caster
          Arel::Table.new(reflection.table_name, type_caster: type_caster)
        }
        [last_table, *rest_tables ]
      end


      def initialize(base, table, associations, join_type, references: nil)
        tree = self.class.make_tree associations
        @references = references
        built = build(tree, base)

        @join_root = JoinBase.new(base, table, built)
        @join_type = join_type
      end

      def build(associations, base_klass, path: ['joins:'])
        associations.map do |name, right|
          reflection = find_reflection base_klass, name
          reflection.check_validity!
          reflection.check_eager_loadable!

          if reflection.polymorphic?
            raise EagerLoadPolymorphicError.new(reflection)
          end
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