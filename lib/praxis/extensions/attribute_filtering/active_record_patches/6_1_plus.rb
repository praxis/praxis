# frozen_string_literal: true
# rubocop:disable all

# FOR AR >= 6.1
module ActiveRecord
  PRAXIS_JOIN_ALIAS_PREFIX = Praxis::Extensions::AttributeFiltering::ALIAS_TABLE_PREFIX
  module Associations
    class JoinDependency
      private

      def make_constraints(parent, child, join_type)
        foreign_table = parent.table
        foreign_klass = parent.base_klass
        child.join_constraints(foreign_table, foreign_klass, join_type, alias_tracker) do |reflection|
          table, terminated = @joined_tables[reflection]
          root = reflection == child.reflection

          if table && (!root || !terminated)
            @joined_tables[reflection] = [table, root] if root
            next table, true
          end

          table_name = @references[reflection.name.to_sym] || @references[:"/#{reflection.name}"]
          # Praxis: set an alias_path in the JoinAssociation if its path matches a requested reference
          table_name ||= @references[child&.alias_path.join('/').to_sym]

          table = alias_tracker.aliased_table_for(reflection.klass.arel_table, table_name) do
            name = reflection.alias_candidate(parent.table_name)
            root ? name : "#{name}_join"
          end

          @joined_tables[reflection] ||= [table, root] if join_type == Arel::Nodes::OuterJoin
          table
        end.concat child.children.flat_map { |c| make_constraints(child, c, join_type) }
      end

      # Praxis: build for is shared for 5x and 6.0
      def build(associations, base_klass, path: [PRAXIS_JOIN_ALIAS_PREFIX])
        associations.map do |name, right|
          reflection = find_reflection base_klass, name
          reflection.check_validity!
          reflection.check_eager_loadable!

          raise EagerLoadPolymorphicError, reflection if reflection.polymorphic?

          # Praxis: set an alias_path in the JoinAssociation if its path matches a requested reference
          child_path = path && !path.empty? ? path + [name] : nil
          association = JoinAssociation.new(reflection, build(right, reflection.klass, path: child_path))
          # association.alias_path = child_path if references.include?(child_path.join('/'))
          association.alias_path = child_path # ??? should be the line above no?
          association
        end
      end
    end

    class ActiveRecord::Associations::JoinDependency::JoinAssociation
      attr_accessor :alias_path
    end
  end
end
# rubocop:enable all