module Praxis
  module Extensions
    module AttributeFiltering
      class ActiveRecordFilterQueryBuilder
      attr_reader :query, :model, :attr_to_column

        # Base query to build upon
        def initialize(query: , model:, filters_map:)
          @query = query
          @model = model
          @attr_to_column = filters_map
        end
        
        def debug(msg)
          puts msg
        end

        def build_clause(filters)
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
          root_node = FilterTreeNode.new(resolved_array, path: [self.model.table_name])
          craft_filter_query(root_node, for_model: @model)
          debug("FILTERS QUERY: #{@query.all.to_sql}")
          @query
        end

        def craft_filter_query(nodetree, for_model:)
          #nodetree.custom_data = { model: for_model }
          nodetree.children.each do |name, child|
            source_alias = nodetree.path.join('/')
            table_alias = (nodetree.path + [name]).join('/')
            debug( "JOINING #{name}: #{source_alias} as #{table_alias}" )

            reflection = for_model.reflections[name.to_s]
            @query = do_join_reflection( query, reflection, source_alias, table_alias )

            craft_filter_query(child, for_model: reflection.klass)
          end
          column_prefix = nodetree.path.join('/')
          nodetree.conditions.each do |condition|
            bindings = \
              if condition[:name].is_a?(Proc)
                condition[:name].call(condition)
              else
                {condition[:name] => condition[:value] } # For non-procs there's only 1 filter and 1 value
              end
            bindings.each do |filter_name,filter_value|
              debug("ADDING condition: #{column_prefix}.#{filter_name} #{condition[:op]} #{filter_value}")
              colo = for_model.columns_hash[filter_name.to_s]
              add_clause(column_prefix: column_prefix,  column_object: colo, op: condition[:op], value: filter_value, column_object: colo)
            end
          end
        end

        # TODO: Support more relationship types (including things like polymorphic..etc)
        def do_join(query, assoc , source_alias, table_alias, source_model:)
          reflection = source_model.reflections[assoc.to_s]
          do_join_reflection( query, reflection, source_alias, table_alias )
        end

        def do_join_reflection( query, reflection, source_alias, table_alias )
          c = query.connection
          # TODO: apply scopes!!!! or maybe try to use ARel instead?
          case reflection
          when ActiveRecord::Reflection::BelongsToReflection
            join_clause = "INNER JOIN %s as %s ON %s.%s = %s.%s " % \
                  [
                    c.quote_table_name(reflection.klass.table_name),
                    c.quote_table_name(table_alias),
                    c.quote_table_name(table_alias),
                    c.quote_column_name(reflection.join_keys.key),
                    c.quote_table_name(source_alias),
                    c.quote_column_name(reflection.join_keys.foreign_key)
                  ]
            query.joins(join_clause)
          when ActiveRecord::Reflection::HasManyReflection
            join_clause = "INNER JOIN %s as %s ON %s.%s = %s.%s " % \
                  [c.quote_table_name(reflection.klass.table_name),
                    c.quote_table_name(table_alias),
                    c.quote_table_name(source_alias),
                    c.quote_column_name(reflection.join_keys.foreign_key),
                    c.quote_table_name(table_alias),
                    c.quote_column_name(reflection.join_keys.key)
                  ]

            # Polymorphic type, add the appropriate condition to restrict the result to the right type
            if reflection.type
              addition = " AND %s.%s = %s" % \
              [ c.quote_table_name(table_alias),
                c.quote_table_name(reflection.type),
                c.quote(reflection.active_record.class_name)]

              join_clause += addition
            end
            query.joins(join_clause)

          when ActiveRecord::Reflection::ThroughReflection
            talias = reflection.through_reflection.table_name
            salias = source_alias

            query = do_join_reflection(query, reflection.through_reflection, salias, talias)
            salias = talias

            through_model = reflection.through_reflection.klass
            through_assoc = reflection.name
            final_reflection = reflection.source_reflection
            do_join_reflection(query, final_reflection, salias, table_alias)
          else
            raise "Joins for this association type are currently UNSUPPORTED: #{reflection.inspect}"
          end
        end

        # Private to try to funnel all column names through `build_clause` that restricts
        # the attribute names better (to allow more difficult SQL injections )
        private def add_clause(column_prefix:, column_object:, op:, value:)
          likeval = get_like_value(value)
          @query =  case op
                    when '='
                      if likeval
                        query.where("#{quote_column_path(column_prefix, column_object)} LIKE ?", likeval)
                      else
                         query.where("#{column_prefix}.#{column_object.name}" =>  value) # Automatically quoted by AR
                      end
                    when '!='
                      if likeval
                        query.where("#{quote_column_path(column_prefix, column_object)} NOT LIKE ?", likeval)
                      else
                        query.where.not("#{column_prefix}.#{column_object.name}" => value) # Automatically quoted by AR
                      end
                    when '>'
                      add_safe_where(tab: column_prefix, col: column_object, op: '>', value: value, )
                    when '<'
                      query.where("#{quote_column_path(column_prefix, column_object)} < ?", value)
                    when '>='
                      query.where("#{quote_column_path(column_prefix, column_object)} >= ?", value)
                    when '<='
                      query.where("#{quote_column_path(column_prefix, column_object)} <= ?", value)
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