# frozen_string_literal: true
# rubocop:disable all
module Praxis
  module Extensions
    class SequelFilterQueryBuilder
      attr_reader :query, :root

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
      # table is necessary when use the strin queries, when the query has multiple tables involved
      # (to disambiguate)
      def initialize(query:, model: )
        @query = query
        @root = model.table_name
      end

      # By default we'll simply use the incoming op and value, and will map
      # the attribute based on what's on the `attr_to_column` hash
      def build_clause(filters)
        raise "Not refactored yet!"
        seen_associations = Set.new
        filters.each do |(attr, spec)|
          column_name = attr_to_column[attr]
          raise "Filtering by #{attr} not allowed (no mapping found)" unless column_name
          if column_name.is_a?(Proc)
            bindings = column_name.call(spec)
            # A hash of bindings, consisting of a key with column name and a value to the query value
            bindings.each{|col,val| expand_binding(column_name: col, op: spec[:op], value: val )}
          else
            expand_binding(column_name: column_name, **spec)
          end
        end
        query
      end

      def expand_binding(column_name:,op:,value:)
        assoc_or_field, *rest = column_name.to_s.split('.')
        if rest.empty?
          column_name = Sequel.qualify(root,column_name)
        else
          puts "Adding eager graph for #{assoc_or_field} due to being used in filter"
          # Ensure the joined table is aliased properly (to the association name) so we can add the condition appropriately
          @query = query.eager_graph(Sequel.as(assoc_or_field.to_sym, assoc_or_field.to_sym) )
          column_name = Sequel.qualify(assoc_or_field, rest.first)
        end
        add_clause(attr: column_name, op: op, value: value)
      end

      def attr_to_column
        # Class method defined by the subclassing Class (using .for)
        self.class.attr_to_column
      end

      # Private to try to funnel all column names through `build_clause` that restricts
      # the attribute names better (to allow more difficult SQL injections )
      private def add_clause(attr:, op:, value:)
        # TODO: partial matching
        #components = attr.to_s.split('.')
        #attr_selector = Sequel.qualify(*components)
        attr_selector = attr
  #      HERE!! if we have "association.name" we should properly join it ...!

  #> ds.eager_graph(:device).where{{device[:name] => 'A%'}}.select(:accountID)
  #=> #<Sequel::Mysql2::Dataset: "SELECT `accountID` FROM `EventData`
  #     LEFT OUTER JOIN `Device` AS `device` ON
  #           ((`device`.`accountID` = `EventData`.`accountID`) AND (`device`.`deviceID` = `EventData`.`deviceID`))
  #      WHERE (`device`.`name` = 'A%')">
        likeval = get_like_value(value)
        @query =  case op
                  when '='
                    if likeval
                      query.where(Sequel.like(attr_selector, likeval))
                    else
                      query.where(attr_selector => value)
                    end
                  when '!='
                    if likeval
                      query.exclude(Sequel.like(attr_selector, likeval))
                    else
                      query.exclude(attr_selector => value)
                    end
                  when '>'
                    #query.where(Sequel.lit("#{attr_selector} > ?", value))
                    query.where{attr_selector > value}
                  when '<'
                    query.where{attr_selector < value}
                  when '>='
                    query.where{attr_selector >= value}
                  when '<='
                    query.where{attr_selector <= value}
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
# rubocop:enable all