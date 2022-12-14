# frozen_string_literal: true

module Praxis
  module Extensions
    module AttributeFiltering
      ALIAS_TABLE_PREFIX = ''
      require_relative 'active_record_patches'
      # Helper class that can present an SqlLiteral string which we have already quoted
      # ... but! that can properly provide a "to_sym" that has the value unquoted
      # This is necessary as (the latest AR code):
      # * does not carry over "references" in joins if they are not SqlLiterals
      # * but, at the same time, it indexes the references using the .to_sym value (which is really expected to be the normal string, without quotes)
      # If we pass a normal SqlLiteral, instead of our wrapper, without quoting the table, the current AR code will never quote it to form the
      # SQL string, as it's already a literal...so our "/" type separators as names won't work without quoting.
      class QuasiSqlLiteral < Arel::Nodes::SqlLiteral
        def initialize(quoted:, symbolized:)
          @symbolized = symbolized
          super(quoted)
        end

        def to_sym
          @symbolized
        end
      end

      class ActiveRecordFilterQueryBuilder
        REFERENCES_STRING_SEPARATOR = '/'
        attr_reader :model, :filters_map, :resulting_filter_aliases

        # Base query to build upon
        def initialize(query:, model:, filters_map:, debug: false)
          # NOTE: Do not make the initial_query an attr reader to make sure we don't count/leak on modifying it. Easier to mostly use class methods
          @initial_query = query
          @model = model
          @filters_map = filters_map
          @treenode = nil
          @logger = debug ? Logger.new($stdout) : nil
          @active_record_version_maj = ActiveRecord.gem_version.segments[0]
          @resulting_filter_aliases = nil # Gets the table/alias used for any given filter name
        end

        def debug_query(msg, query)
          @logger&.info(msg + query.to_sql)
        end

        def generate(filters)
          # Resolve the names and values first, based on filters_map
          root_node = _convert_to_treenode(filters)
          # Save the aliases that will result from the applied filters
          @resulting_filter_aliases = root_node.dump_mappings.each_with_object({}) do |(filter_name, path), result|
            table_alias_name = path == [ALIAS_TABLE_PREFIX] ? model.table_name : path.join(REFERENCES_STRING_SEPARATOR)
            result[filter_name] = table_alias_name
          end
          crafted = craft_filter_query(root_node, for_model: @model)
          debug_query('SQL due to filters: ', crafted.all)
          crafted
        end

        def craft_filter_query(nodetree, for_model:)
          result = _compute_joins_and_conditions_data(nodetree, model: for_model, parent_reflection: nil)
          return @initial_query if result[:conditions].empty?

          # Find the root group (usually an AND group) but can be an OR group, or nil if there's only 1 condition
          root_parent_group = result[:conditions].first[:node_object].parent_group || result[:conditions].first[:node_object]
          root_parent_group = root_parent_group.parent_group until root_parent_group.parent_group.nil?

          # Process the joins
          query_with_joins = result[:associations_hash].empty? ? @initial_query : @initial_query.left_outer_joins(result[:associations_hash])

          # Proc to apply a single condition
          apply_single_condition = proc do |condition, associated_query|
            colo = condition[:model].columns_hash[condition[:name].to_s]
            column_prefix = condition[:column_prefix]
            association_key_column = \
              if (ref = condition[:parent_reflection])
                # get the target model of the association(where the assoc pk is)
                target_model = ref.klass
                target_model.columns_hash[ref.association_primary_key]
              end

            # Mark where clause referencing the appropriate alias IF it's not the root table, as there is no association to reference
            # If we added root table as a reference, we better make sure it is not quoted, as it actually makes AR to see it as an
            # unmatched reference and eager loads the whole association (it means eager load ALL the things). Not good.
            associated_query = associated_query.references(build_reference_value(column_prefix, query: associated_query)) unless for_model.table_name == column_prefix
            self.class.add_clause(
              query: associated_query,
              column_prefix: column_prefix,
              column_object: colo,
              op: condition[:op],
              value: condition[:value],
              fuzzy: condition[:fuzzy],
              association_key_column: association_key_column
            )
          end

          if @active_record_version_maj < 6
            # ActiveRecord < 6 does not support '.and' so no nested things can be done
            # But we can still support the case of 1+ flat conditions of the same AND/OR type
            if root_parent_group.is_a?(FilteringParams::Condition)
              # A Single condition it is easy to handle
              apply_single_condition.call(result[:conditions].first, query_with_joins)
            elsif root_parent_group.items.all? { |i| i.is_a?(FilteringParams::Condition) }
              # Only 1 top level root, with only with simple condition items
              if root_parent_group.type == :and
                result[:conditions].reverse.inject(query_with_joins) do |accum, condition|
                  apply_single_condition.call(condition, accum)
                end
              else
                # To do a flat OR, we need to apply the first condition to the incoming query
                # and then apply any extra ORs to it. Otherwise Book.or(X).or(X) still matches all books
                cond1, *rest = result[:conditions].reverse
                start_query = apply_single_condition.call(cond1, query_with_joins)
                rest.inject(start_query) do |accum, condition|
                  accum.or(apply_single_condition.call(condition, query_with_joins))
                end
              end
            else
              raise 'Mixing AND and OR conditions is not supported for ActiveRecord <6.'
            end
          else #  ActiveRecord 6+
            # Process the conditions in a depth-first order, and return the resulting query
            _depth_first_traversal(
              root_query: query_with_joins,
              root_node: root_parent_group,
              conditions: result[:conditions],
              &apply_single_condition
            )
          end
        end

        # not in filters....checks if it's a valid path
        # array of strings
        def self.valid_path?(model, path)
          first_component, *rest = path
          if model.attribute_names.include?(first_component)
            true
          elsif model.reflections.keys.include?(first_component)
            if rest.empty?
              true # Allow associations as a leaf too (as they can have the ! and !! operator)
            else # Follow the association
              nested_model = model.reflections[first_component].klass
              valid_path?(nested_model, rest)
            end
          else
            false
          end
        end

        # rubocop:disable Metrics/ParameterLists,Naming/MethodParameterName
        def self.add_clause(query:, column_prefix:, column_object:, op:, value:, fuzzy:, association_key_column:)
          likeval = get_like_value(value, fuzzy)

          association_op = nil
          case op
          when '!' # name! means => name IS NOT NULL (and the incoming value is nil)
            op = '!='
            value = nil # Enforce it is indeed nil (should be)
            association_op = :not_null if association_key_column && !column_object
          when '!!'
            op = '='
            value = nil # Enforce it is indeed nil (should be)
            association_op = :null if association_key_column && !column_object
          end

          if association_op
            neg = association_op == :not_null
            qr = quote_right_part(query: query, value: nil, column_object: association_key_column, negative: neg)
            return query.where("#{quote_column_path(query: query, prefix: column_prefix, column_object: association_key_column)} #{qr}")
          end

          # Add an AND along with the condition, which ensures the left outter join 'exists' for it
          # Normally this wouldn't be necessary as a condition on a given value mathing would imply the related row was there
          # but this is not the case for NULL conditions, as the foreign column would match a  NULL value, but not because the related column
          # is NULL, but because the whole missing related row would appear with all fields null
          # NOTE: we don't need to do it for conditions applying to the root of the tree (there isn't a join to it)
          if association_key_column
            qr = quote_right_part(query: query, value: nil, column_object: association_key_column, negative: true)
            query = query.where("#{quote_column_path(query: query, prefix: column_prefix, column_object: association_key_column)} #{qr}")
          end

          case op
          when '='
            if likeval
              add_safe_where(query: query, tab: column_prefix, col: column_object, op: 'LIKE', value: likeval)
            else
              quoted_right = quote_right_part(query: query, value: value, column_object: column_object, negative: false)
              query.where("#{quote_column_path(query: query, prefix: column_prefix, column_object: column_object)} #{quoted_right}")
            end
          when '!='
            if likeval
              add_safe_where(query: query, tab: column_prefix, col: column_object, op: 'NOT LIKE', value: likeval)
            else
              quoted_right = quote_right_part(query: query, value: value, column_object: column_object, negative: true)
              query.where("#{quote_column_path(query: query, prefix: column_prefix, column_object: column_object)} #{quoted_right}")
            end
          when '>'
            add_safe_where(query: query, tab: column_prefix, col: column_object, op: '>', value: value)
          when '<'
            add_safe_where(query: query, tab: column_prefix, col: column_object, op: '<', value: value)
          when '>='
            add_safe_where(query: query, tab: column_prefix, col: column_object, op: '>=', value: value)
          when '<='
            add_safe_where(query: query, tab: column_prefix, col: column_object, op: '<=', value: value)
          else
            raise "Unsupported Operator!!! #{op}"
          end
        end
        # rubocop:enable Metrics/ParameterLists,Naming/MethodParameterName

        # rubocop:disable Naming/MethodParameterName
        def self.add_safe_where(query:, tab:, col:, op:, value:)
          quoted_value = query.connection.quote_default_expression(value, col)
          query.where("#{quote_column_path(query: query, prefix: tab, column_object: col)} #{op} #{quoted_value}")
        end
        # rubocop:enable Naming/MethodParameterName

        def self.quote_column_path(query:, prefix:, column_object:)
          c = query.connection
          quoted_column = c.quote_column_name(column_object.name)
          if prefix
            quoted_table = c.quote_table_name(prefix)
            "#{quoted_table}.#{quoted_column}"
          else
            quoted_column
          end
        end

        def self.quote_right_part(query:, value:, column_object:, negative:)
          conn = query.connection
          if value.nil?
            no = negative ? ' NOT' : ''
            "IS#{no} #{conn.quote_default_expression(value, column_object)}"
          elsif value.is_a?(Array)
            no = negative ? 'NOT ' : ''
            list = value.map { |v| conn.quote_default_expression(v, column_object) }
            "#{no}IN (#{list.join(',')})"
          elsif value.is_a?(Range)
            raise 'TODO!'
          else
            op = negative ? '<>' : '='
            "#{op} #{conn.quote_default_expression(value, column_object)}"
          end
        end

        # Returns nil if the value was not a fuzzzy pattern
        def self.get_like_value(value, fuzzy)
          is_fuzzy = fuzzy.is_a?(Array) ? !fuzzy.compact.empty? : fuzzy
          return unless is_fuzzy

          raise MultiMatchWithFuzzyNotAllowedByAdapter unless value.is_a?(String)

          case fuzzy
          when :start_end
            "%#{value}%"
          when :start
            "%#{value}"
          when :end
            "#{value}%"
          end
        end

        private

        def _depth_first_traversal(root_query:, root_node:, conditions:, &block)
          # Save the associated query for non-leaves
          root_node.associated_query = root_query if root_node.is_a?(FilteringParams::ConditionGroup)

          if root_node.is_a?(FilteringParams::Condition)
            matching_condition = conditions.find { |cond| cond[:node_object] == root_node }

            # The simplified case of a single top level condition (without a wrapping group)
            # will need to pass the root query itself
            associated_query = root_node.parent_group ? root_node.parent_group.associated_query : root_query
            yield matching_condition, associated_query
          else
            first_query, *rest_queries = root_node.items.map do |child|
              _depth_first_traversal(root_query: root_query, root_node: child, conditions: conditions, &block)
            end

            rest_queries.each.inject(first_query) do |q, a_query|
              root_node.type == :and ? q.and(a_query) : q.or(a_query)
            end
          end
        end

        def _mapped_filter(name)
          target = @filters_map[name]
          unless target
            path = name.to_s.split('.')
            if self.class.valid_path?(@model, path)
              # Cache it in the filters mapping (to avoid later lookups), and return it.
              @filters_map[name] = name
              target = name
            end
          end
          target
        end

        # Resolve and convert from filters, to a more manageable and param-type-independent structure
        def _convert_to_treenode(filters)
          # Resolve the names and values first, based on filters_map
          resolved_array = []
          filters.parsed_array.each do |filter|
            mapped_value = _mapped_filter(filter[:name])
            unless mapped_value
              msg = "Filtering by #{filter[:name]} is not allowed. No implementation mapping defined for it has been found \
                and there is not a model attribute with this name either.\n" \
                "Please add a mapping for #{filter[:name]} in the `filters_mapping` method of the appropriate Resource class"
              raise msg
            end
            bindings_array = \
              if mapped_value.is_a?(Proc)
                result = mapped_value.call(filter)
                # Result could be an array of hashes (each hash has name/op/value to identify a condition)
                result_from_proc = result.is_a?(Array) ? result : [result]
                # Make sure we tack on the node object associated with the filter
                result_from_proc.map { |hash| hash.merge(node_object: filter[:node_object], orig_name: filter[:name]) } # Original name is the best we can do
              else
                # For non-procs there's only 1 filter and 1 value (we're just overriding the mapped value)
                [filter.merge(name: mapped_value, orig_name: mapped_value)]
              end
            resolved_array += bindings_array
          end
          FilterTreeNode.new(resolved_array, path: [ALIAS_TABLE_PREFIX])
        end

        # Calculate join tree and conditions array for the nodetree object and its children
        def _compute_joins_and_conditions_data(nodetree, model:, parent_reflection:)
          h = {}
          conditions = []
          nodetree.children.each do |name, child|
            child_reflection = model.reflections[name.to_s]
            result = _compute_joins_and_conditions_data(child, model: child_reflection.klass, parent_reflection: child_reflection)
            h[name] = result[:associations_hash]

            conditions += result[:conditions]
          end

          column_prefix = nodetree.path == [ALIAS_TABLE_PREFIX] ? model.table_name : nodetree.path.join(REFERENCES_STRING_SEPARATOR)
          nodetree.conditions.each do |condition|
            # If it's a final ! or !! operation on an association from the parent, it means we need to add a condition
            # on the existence (or lack of) of the whole associated table
            ref = model.reflections[condition[:name].to_s]
            if ref && ['!', '!!'].include?(condition[:op])
              cp = (nodetree.path + [condition[:name].to_s]).join(REFERENCES_STRING_SEPARATOR)
              conditions += [condition.merge(column_prefix: cp, model: model, parent_reflection: ref)]
              h[condition[:name]] = {}
            else
              # Save the parent reflection where the condition applies as well (used later to get assoc keys)
              conditions += [condition.merge(column_prefix: column_prefix, model: model, parent_reflection: parent_reflection)]
            end
          end
          { associations_hash: h, conditions: conditions }
        end

        # The value that we need to stick in the references method is different in the latest Rails
        maj, min, = ActiveRecord.gem_version.segments
        if maj == 5 || (maj == 6 && min.zero?)
          # In AR 6 (and 6.0) the references are simple strings
          def build_reference_value(column_prefix, **_args)
            column_prefix
          end
        else
          # The latest AR versions discard passing references to joins when they're not SqlLiterals ... so let's wrap it
          # with our class, so that it is a literal (already quoted), but that can still provide the expected "symbol" without quotes
          # so that our aliasing code can match it.
          def build_reference_value(column_prefix, query:)
            QuasiSqlLiteral.new(quoted: query.connection.quote_table_name(column_prefix), symbolized: column_prefix.to_sym)
          end
        end
      end
    end
  end
end
