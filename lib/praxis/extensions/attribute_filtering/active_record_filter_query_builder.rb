module Praxis
  module Extensions
    class ActiveRecordFilterQueryBuilder
    attr_reader :query, :table, :model

    # Abstract class, which needs to be used by subclassing it through the .for method, to set the mapping of attributes
    class << self
      def for(definition)
        Class.new(self) do
          @attr_to_column = case definition
                            when Hash
                                definition
                              when Array
                                definition.each_with_object({}) { |item, hash| hash[item.to_sym] = item }
                              else
                                raise "Cannot use FilterQueryBuilder.of without passing an array or a hash (Got: #{definition.class.name})"
                              end
            class << self
              attr_reader :attr_to_column
            end
          end
        end
      end

      # Base query to build upon
      def initialize(query: , model: )
        @query = query
        @table = model.table_name
        @last_join_alias = model.table_name
        @alias_counter = 0;
      end

      def pick_alias( name )
        @alias_counter += 1
        "#{name}#{@alias_counter}"
      end

      def build_clause(filters)
        filters.each do |(attr, spec)|
          column_name = attr_to_column[attr]
          raise "Filtering by #{attr} not allowed (no mapping found)" unless column_name
          if column_name.is_a?(Proc)
            bindings = column_name.call(spec)
            # A hash of bindings, consisting of a key with column name and a value to the query value
            bindings.each do|col,val|
              assoc_or_field, *rest = col.to_s.split('.')
              expand_binding(column_name: assoc_or_field, rest: rest, op: spec[:op], value: val, use_this_name_for_clause: @last_join_alias)
            end
          else
            assoc_or_field, *rest = column_name.to_s.split('.')
            expand_binding(column_name: assoc_or_field, rest: rest, **spec, use_this_name_for_clause: @last_join_alias)
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
                [c.quote_table_name(reflection.klass.table_name),
                  c.quote_table_name(table_alias),
                  c.quote_table_name(table_alias),
                  c.quote_column_name(reflection.association_primary_key),
                  c.quote_table_name(source_alias),
                  c.quote_column_name(reflection.association_foreign_key)
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
          #puts "TODO: choose different alias (based on matching table type...)"
          talias = pick_alias(reflection.through_reflection.table_name)
          salias = source_alias

          query = do_join_reflection(query, reflection.through_reflection, salias, talias)
          #puts "TODO: choose different alias ?????????"
          salias = talias

          through_model = reflection.through_reflection.klass
          through_assoc = reflection.delegate_reflection.name
          final_reflection = reflection.source_reflection

          do_join_reflection(query, final_reflection, salias, table_alias)
        else
          raise "Joins for this association type are currently UNSUPPORTED: #{reflection.inspect}"
        end
      end

      def expand_binding(column_name:,rest: , op:,value:, use_this_name_for_clause: column_name)
        unless rest.empty?
          joined_alias = pick_alias(column_name)
          @query = do_join(query, column_name, @last_join_alias, joined_alias)
          saved_join_alias = @last_join_alias
          @last_join_alias = joined_alias
          new_column_name, *new_rest = rest
          expand_binding(column_name: new_column_name, rest: new_rest, op: op, value: value, use_this_name_for_clause: joined_alias)
          @last_join_alias = saved_join_alias          
        else
          column_name = "#{use_this_name_for_clause}.#{column_name}"
          add_clause(column_name: column_name, op: op, value: value)
        end
      end

      def attr_to_column
        # Class method defined by the subclassing Class (using .for)
        self.class.attr_to_column
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