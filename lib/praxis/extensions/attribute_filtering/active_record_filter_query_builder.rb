module Praxis
  module Extensions
    module AttributeFiltering
      class ActiveRecordFilterQueryBuilder
      attr_reader :query, :table, :model, :attr_to_column

        # Base query to build upon
        def initialize(query: , model:, filters_map:)
          @query = query
          @model = model
          @table = model.table_name
          @attr_to_column = filters_map
        end

        def new_build(nodetree, for_model:)
          nodetree.children.each do |name, child|
            source_alias = nodetree.path.join('/')
            table_alias = (nodetree.path + [name]).join('/')
            puts "JOINING #{name}: #{source_alias} as #{table_alias}"

            reflection = for_model.reflections[name.to_s]
            puts "REFLECTION for #{name.to_s}: #{reflection} (QUERY: #{reflection.klass})"
            @query = do_join_reflection( query, reflection, source_alias, table_alias )

            #@query = do_join(query, name, source_alias, table_alias, source_model: for_model)
            new_build(child, for_model: reflection.klass)
          end
          c = query.connection
          name_prefix = c.quote_table_name(nodetree.path.join('/'))
          name_prefix = nodetree.path.join('/')
          nodetree.conditions.each do |condition|
            bindings = \
              if condition[:name].is_a?(Proc)
                condition[:name].call(condition)
              else
                {condition[:name] => condition[:value] } # For non-procs there's only 1 filter and 1 value
              end
            bindings.each do |filter_name,filter_value|
              #expanded_column_name = "#{name_prefix}.#{c.quote_column_name(filter_name)}"
              expanded_column_name = "#{name_prefix}.#{filter_name}"
              puts "ADDING condition: #{expanded_column_name} #{condition[:op]} #{filter_value}"
              add_clause(column_name: expanded_column_name, op: condition[:op], value: filter_value)
            end
          end
          @query
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
          root_node = FilterTreeNode.new(resolved_array, path: [self.table])
          new_build(root_node, for_model: @model)
          #return query
        #   filters.each do |item|
        #     spec = item[:specs]
        #     column_name = attr_to_column[item[:name]]
        #     raise "Filtering by #{item[:name]} not allowed (no mapping found)" unless column_name
        #     bindings = \
        #       if column_name.is_a?(Proc)
        #         column_name.call(spec)
        #       else
        #         {column_name => spec[:value] } # For non-procs there's only 1 filter and 1 value
        #       end

        #     bindings.each do|filter_segments,filter_value|
        #       first_segment, *rest = filter_segments.to_s.split('.')
        #       #path = [first_segment]
        #       expand_binding(first_segment: first_segment, rest: rest, op: spec[:op], value: filter_value, use_this_name_for_clause: self.table)
        #     end
        #   end
        #   query
        end

        # TODO: Support more relationship types (including things like polymorphic..etc)
        def do_join(query, assoc , source_alias, table_alias, source_model:)
          reflection = source_model.reflections[assoc.to_s]
          puts "REFLECTION for #{assoc.to_s}: #{reflection} (QUERY: #{query.class})"
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
            join_clause = "INNER JOIN %s as %s ON %s.%s = %s.%s " % \
                  [c.quote_table_name(reflection.klass.table_name),
                    c.quote_table_name(table_alias),
                    c.quote_table_name(source_alias),
                    c.quote_column_name(reflection.join_keys.foreign_key),
                    c.quote_table_name(table_alias),
                    c.quote_column_name(reflection.join_keys.key)
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

        # def expand_binding(first_segment:, rest: , op:, value:, use_this_name_for_clause:)
        #   #puts "EXPAND FOR: first_segment: #{first_segment} USE: #{use_this_name_for_clause}"
        #   if rest.empty?
        #     #puts "ADDING CLAUSE"
        #     expanded_column_name = "#{use_this_name_for_clause}.#{first_segment}"
        #     add_clause(column_name: expanded_column_name, op: op, value: value)
        #   else # Join and continue with more segments
        #     @query = do_join(query, first_segment, use_this_name_for_clause, first_segment)
        #     puts "JOINING: #{first_segment} Q: #{self.query.all.to_sql}"
        #     puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        #     new_first_segment, *new_rest = rest
        #     # TODO: Should the use_this_name_for_clause be new_first_segment rather than first_segment? ... fails it if is...look into it, maybe its fine
        #     expand_binding(first_segment: new_first_segment, rest: new_rest, op: op, value: value, use_this_name_for_clause: first_segment)
        #   end
        # end

        # Private to try to funnel all column names through `build_clause` that restricts
        # the attribute names better (to allow more difficult SQL injections )
        private def add_clause(column_name:, op:, value:)
          likeval = get_like_value(value)
          @query =  case op
                    when '='
                      if likeval
                        query.where("#{column_name} LIKE ?", likeval)
                      else
                        # TODO: recreate the array and null feeling of a native hash
#                        query.where("%s = %s",column_name, value)
#                        query.where("#{column_name} = :value", {value: value} )
#                        query.where("#{column_name} = ?", value)
                         query.where(column_name =>  value)
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