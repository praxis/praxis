module Praxis
  module Extensions
    module AttributeFiltering
      class ActiveRecordFilterQueryBuilder
      attr_reader :query, :table, :model, :attr_to_column

        # Base query to build upon
        def initialize(query: , model:, filters_map:)
          @query = query
          @table = model.table_name
          @attr_to_column = filters_map
        end

        def build_clause(filters)
          filters.each do |item|
            spec = item[:specs]
            column_name = attr_to_column[item[:name]]
            raise "Filtering by #{attr} not allowed (no mapping found)" unless column_name
            bindings = \
              if column_name.is_a?(Proc)
                column_name.call(spec)
              else
                {column_name => spec[:value] } # For non-procs there's only 1 filter and 1 value
              end

            bindings.each do|filter_segments,filter_value|
              first_segment, *rest = filter_segments.to_s.split('.')
              expand_binding(first_segment: first_segment, rest: rest, op: spec[:op], value: filter_value, use_this_name_for_clause: self.table)
            end
          end
          query
        end

        # TODO: Support more relationship types (including things like polymorphic..etc)
        def do_join(query, assoc , source_alias, table_alias)
          reflection = query.reflections[assoc.to_s]
          do_join_reflection( query, reflection, source_alias, table_alias )
        end

        def do_join_reflection( query, reflection, source_alias, table_alias )
          c = query.connection
          ref = case reflection
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
            # join_clause = "INNER JOIN #{reflection.klass.table_name} as #{table_alias} ON"  + \
            #       " \"#{source_alias}\".\"id\" = \"#{table_alias}\".\"#{reflection.foreign_key}\" "
            join_clause = "INNER JOIN %s as %s ON %s.%s = %s.%s " % \
                  [c.quote_table_name(reflection.klass.table_name),
                    c.quote_table_name(table_alias),
                    c.quote_table_name(source_alias),
                    c.quote_column_name(reflection.active_record.primary_key),
                    c.quote_table_name(table_alias),
                    c.quote_column_name(reflection.foreign_key)
                  ]

            # Polymorphic type, add the appropriate condition to restrict the result to the right type
            if reflection.type # && reflection.options[:as]....
              #addition = " AND \"#{table_alias}\".\"#{reflection.type}\" = \'#{reflection.active_record.class_name}\'"
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

            puts "FIRST"
            query = do_join_reflection(query, reflection.through_reflection, salias, talias)
            #puts "TODO: choose different alias ?????????"
            salias = talias

            through_model = reflection.through_reflection.klass
            through_assoc = reflection.name
            final_reflection = reflection.source_reflection
            puts "LAST"
            do_join_reflection(query, final_reflection, salias, table_alias)
          else
            raise "Joins for this association type are currently UNSUPPORTED: #{reflection.inspect}"
          end
          puts ">>>#{ref.to_sql}"
          ref
        end

        def expand_binding(first_segment:, rest: , op:, value:, use_this_name_for_clause:)
          if rest.empty?
            expanded_column_name = "#{use_this_name_for_clause}.#{first_segment}"
            add_clause(column_name: expanded_column_name, op: op, value: value)
          else # Join and continue with more segments
            @query = do_join(query, first_segment, use_this_name_for_clause, first_segment)
            new_first_segment, *new_rest = rest
            expand_binding(first_segment: new_first_segment, rest: new_rest, op: op, value: value, use_this_name_for_clause: first_segment)
          end
        end

        # Private to try to funnel all column names through `build_clause` that restricts
        # the attribute names better (to allow more difficult SQL injections )
        private def add_clause(column_name:, op:, value:)
          likeval = get_like_value(value)
          @query =  case op
                    when '='
                      if likeval
                        query.where("#{column_name} LIKE ?", likeval)
                      else
                        query.where(column_name => value)
                      end
                    when '!='
                      if likeval
                        query.where("#{column_name} NOT LIKE ?", likeval)
                      else
                        query.where.not(column_name => value)
                      end
                    when '>'
                      query.where("#{column_name} > ?", value)
                    when '<'
                      query.where("#{column_name} < ?", value)
                    when '>='
                      query.where("#{column_name} >= ?", value)
                    when '<='
                      query.where("#{column_name} <= ?", value)
                    else
                      raise "Unsupported Operator!!! #{op}"
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