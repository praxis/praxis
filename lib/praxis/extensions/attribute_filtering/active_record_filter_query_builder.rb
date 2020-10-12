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
            attr = item[:name]
            spec = item[:specs]
            column_name = attr_to_column[attr]
            raise "Filtering by #{attr} not allowed (no mapping found)" unless column_name
            if column_name.is_a?(Proc)
              bindings = column_name.call(spec)
              # A hash of bindings, consisting of a key with column name and a value to the query value
              # TODO: just get the bindings here...and use a single 2 liner at the end of the build clause ... since it's repeated
              bindings.each do|col,val|
                assoc_or_field, *rest = col.to_s.split('.')
                expand_binding(first_segment: assoc_or_field, rest: rest, op: spec[:op], value: val, use_this_name_for_clause: self.table)
              end
            else
              assoc_or_field, *rest = column_name.to_s.split('.')
              puts "FILTERING FOR: #{assoc_or_field}"
              expand_binding(first_segment: assoc_or_field, rest: rest, **spec, use_this_name_for_clause: self.table)
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
      #        join_clause = "INNER JOIN #{reflection.klass.table_name} as #{table_alias} ON"  + \
      #              " \"#{source_alias}\".\"id\" = \"#{table_alias}\".\"#{reflection.foreign_key}\" "
            join_clause = "INNER JOIN %s as %s ON %s.%s = %s.%s " % \
                  [c.quote_table_name(reflection.klass.table_name),
                    c.quote_table_name(table_alias),
                    c.quote_table_name(source_alias),
                    c.quote_column_name(reflection.active_record.primary_key),
                    c.quote_table_name(table_alias),
                    c.quote_column_name(reflection.foreign_key)
                  ]

            # TODO: This is to support polymorphic things I think...redo
            if reflection.type # && reflection.options[:as]....
      #          addition = " AND \"#{table_alias}\".\"#{reflection.type}\" = \'#{reflection.active_record.class_name}\'"
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
            #puts "TODO: choose different alias ?????????"
            salias = talias

            through_model = reflection.through_reflection.klass
            through_assoc = reflection.name
            final_reflection = reflection.source_reflection

            do_join_reflection(query, final_reflection, salias, table_alias)
          else
            raise "Joins for this association type are currently UNSUPPORTED: #{reflection.inspect}"
          end
        end

        def expand_binding(first_segment:, rest: , op:, value:, use_this_name_for_clause:)
          unless rest.empty?
            @query = do_join(query, first_segment, use_this_name_for_clause, first_segment)
            new_first_segment, *new_rest = rest
            expand_binding(first_segment: new_first_segment, rest: new_rest, op: op, value: value, use_this_name_for_clause: first_segment)
          else
            new_first_segment = "#{use_this_name_for_clause}.#{first_segment}"
            puts "EXPAND FOR: #{first_segment} [join alias: #{use_this_name_for_clause}]"
            add_clause(column_name: new_first_segment, op: op, value: value)
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