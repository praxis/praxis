# frozen_string_literal: true
# rubocop:disable all

require 'active_record'

module ActiveRecord
  PRAXIS_JOIN_ALIAS_PREFIX = Praxis::Extensions::AttributeFiltering::ALIAS_TABLE_PREFIX
  class Relation
    def construct_join_dependency
      including = eager_load_values + includes_values
      # Praxis: inject references into the join dependency
      ActiveRecord::Associations::JoinDependency.new(
        klass, table, including, references: references_values
      )
    end

    def build_join_query(manager, buckets, join_type, aliases)
      buckets.default = []

      association_joins = buckets[:association_join]
      stashed_joins     = buckets[:stashed_join]
      join_nodes        = buckets[:join_node].uniq
      string_joins      = buckets[:string_join].map(&:strip).uniq

      join_list = join_nodes + convert_join_strings_to_ast(string_joins)
      alias_tracker = alias_tracker(join_list, aliases)

      # Praxis: inject references into the join dependency
      join_dependency = ActiveRecord::Associations::JoinDependency.new(
        klass, table, association_joins, references: references_values
      )

      joins = join_dependency.join_constraints(stashed_joins, join_type, alias_tracker)
      joins.each { |join| manager.from(join) }

      manager.join_sources.concat(join_list)

      alias_tracker.aliases
    end
  end

  module Associations
    class JoinDependency
      attr_accessor :references

      private

      def initialize(base, table, associations, references:)
        tree = self.class.make_tree associations
        @references = references # Save the references values into the instance (to use during build)
        @join_root = JoinBase.new(base, table, build(tree, base))
      end

      # Praxis: table aliases for is shared for 5x and 6.0
      def table_aliases_for(parent, node)
        node.reflection.chain.map do |reflection|
          is_root_reflection = reflection == node.reflection
          table = alias_tracker.aliased_table_for(
            reflection.table_name,
            table_alias_for(reflection, parent, !is_root_reflection),
            reflection.klass.type_caster
          )
          # through tables do not need a special alias_path alias (as they shouldn't really referenced by the client)
          if is_root_reflection && node.alias_path
            table = table.left if table.is_a?(Arel::Nodes::TableAlias) # un-alias it if necessary
            table = table.alias(node.alias_path.join('/'))
          end
          table
        end
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
# rubocop:enable all