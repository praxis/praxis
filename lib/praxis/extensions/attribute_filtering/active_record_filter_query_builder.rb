

module Praxis
  module Extensions
    module AttributeFiltering
      ALIAS_TABLE_PREFIX = ''
      require_relative 'active_record_patches'

      class ActiveRecordFilterQueryBuilder
      attr_reader :query, :model, :attr_to_column

        # Base query to build upon
        def initialize(query: , model:, filters_map:)
          @query = query
          @model = model
          @attr_to_column = filters_map
        end
        
        def debug(msg)
          # TODO: User the mapper config? ...
          #puts msg
        end

        def build_clause(filters)
          # Resolve the names and values first, based on filters_map
          root_node = _convert_to_treenode(filters)
          craft_filter_query(root_node, for_model: @model)
          debug("FILTERS QUERY: #{@query.all.to_sql}")
          @query
        end

        def craft_filter_query(nodetree, for_model:)
          result = _compute_joins_and_conditions_data(nodetree, model: for_model)
          @query = query.joins(result[:associations_hash]) unless result[:associations_hash].empty?

          result[:conditions].each do |condition|
            filter_name = condition[:name]
            filter_value = condition[:value]
            column_prefix = condition[:column_prefix]
            debug("ADDING condition: #{column_prefix}.#{filter_name} #{condition[:op]} #{filter_value}")

            colo = condition[:model].columns_hash[filter_name.to_s]
            add_clause(column_prefix: column_prefix,  column_object: colo, op: condition[:op], value: filter_value)
          end
        end

        private

        # Resolve and convert from filters, to a more manageable and param-type-independent structure
        def _convert_to_treenode(filters)
          # Resolve the names and values first, based on filters_map
          resolved_array = []
          filters.parsed_array.each do |filter|
            mapped_value = attr_to_column[filter[:name]]
            raise "Filtering by #{filter[:name]} not allowed (no mapping found)" unless mapped_value
            bindings_array = \
              if mapped_value.is_a?(Proc)
                result = mapped_value.call(filter)
                # Result could be an array of hashes (each hash has name/op/value to identify a condition)
                result.is_a?(Array) ? result : [result]
              else
                # For non-procs there's only 1 filter and 1 value (we're just overriding the mapped value)
                [filter.merge( name: mapped_value)]
              end
            resolved_array = resolved_array + bindings_array
          end
          FilterTreeNode.new(resolved_array, path: [ALIAS_TABLE_PREFIX])
        end

        # Calculate join tree and conditions array for the nodetree object and its children
        def _compute_joins_and_conditions_data(nodetree, model:)
          h = {}
          conditions = []
          nodetree.children.each do |name, child|
            child_model = model.reflections[name.to_s].klass
            result = _compute_joins_and_conditions_data(child, model: child_model)
            h[name] = result[:associations_hash] 
            conditions += result[:conditions]
          end
          column_prefix = nodetree.path == [ALIAS_TABLE_PREFIX] ? model.table_name : nodetree.path.join('/')
          #column_prefix = nodetree.path == [ALIAS_TABLE_PREFIX] ? nil : nodetree.path.join('/')
          nodetree.conditions.each do |condition|
            conditions += [condition.merge(column_prefix: column_prefix, model: model)]
          end
          {associations_hash: h, conditions: conditions}
        end

        def add_clause(column_prefix:, column_object:, op:, value:)
          @query = @query.references(column_prefix) #Mark where clause referencing the appropriate alias
          likeval = get_like_value(value)
          case op
            when '!' # name! means => name IS NOT NULL (and the incoming value is nil)
              op = '!='
              value = nil # Enforce it is indeed nil (should be)
            when '!!'
              op = '='
              value = nil # Enforce it is indeed nil (should be)
            end
          @query =  case op
                    when '='
                      if likeval
                        add_safe_where(tab: column_prefix, col: column_object, op: 'LIKE', value: likeval)
                      else
                        quoted_right = quote_right_part(value: value, column_object: column_object, negative: false)
                        query.where("#{quote_column_path(column_prefix, column_object)} #{quoted_right}")
                      end
                    when '!='
                      if likeval
                        add_safe_where(tab: column_prefix, col: column_object, op: 'NOT LIKE', value: likeval)
                      else
                        quoted_right = quote_right_part(value: value, column_object: column_object, negative: true)
                        query.where("#{quote_column_path(column_prefix, column_object)} #{quoted_right}")
                      end
                    when '>'
                      add_safe_where(tab: column_prefix, col: column_object, op: '>', value: value)
                    when '<'
                      add_safe_where(tab: column_prefix, col: column_object, op: '<', value: value)
                    when '>='
                      add_safe_where(tab: column_prefix, col: column_object, op: '>=', value: value)
                    when '<='
                      add_safe_where(tab: column_prefix, col: column_object, op: '<=', value: value)
                    else
                      raise "Unsupported Operator!!! #{op}"
                    end
        end

        def add_safe_where(tab:, col:, op:, value:)
          quoted_value = query.connection.quote_default_expression(value,col)
          query.where("#{quote_column_path(tab, col)} #{op} #{quoted_value}")
        end

        def quote_column_path(prefix, column_object)
          c = query.connection
          quoted_column = c.quote_column_name(column_object.name)
          if prefix
            quoted_table = c.quote_table_name(prefix)
            "#{quoted_table}.#{quoted_column}"
          else
            quoted_column
          end
        end

        def quote_right_part(value:, column_object:, negative:)
          conn = query.connection
          if value.nil?
            no = negative ? ' NOT' : ''
            "IS#{no} #{conn.quote_default_expression(value,column_object)}"
          elsif value.is_a?(Array)
            no = negative ? 'NOT ' : ''
            list = value.map{|v| conn.quote_default_expression(v,column_object)}
            "#{no}IN (#{list.join(',')})"
          elsif value && value.is_a?(Range)
            raise "TODO!"
          else
            op = negative ? '<>' : '='
            "#{op} #{conn.quote_default_expression(value,column_object)}"
          end
        end

        # Returns nil if the value was not a fuzzzy pattern
        def get_like_value(value)
          if value.is_a?(String) && (value[-1] == '*' || value[0] == '*')
            likeval = value.dup
            likeval[-1] = '%' if value[-1] == '*'
            likeval[0] = '%' if value[0] == '*'
            likeval
          end
        end
      end
    end
  end
end