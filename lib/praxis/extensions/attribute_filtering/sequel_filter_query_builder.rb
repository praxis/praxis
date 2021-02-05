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
            @filters_map = case definition
                              when Hash
                                definition
                              when Array
                                definition.each_with_object({}) { |item, hash| hash[item.to_sym] = item }
                              else
                                raise "Cannot use FilterQueryBuilder.of without passing an array or a hash (Got: #{definition.class.name})"
                              end
            class << self
              attr_reader :filters_map
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
      # the attribute based on what's on the `filters_map` definition
      def generate(filters)
        raise "Not refactored yet!"
        seen_associations = Set.new
        filters.each do |(attr, spec)|
          column_name = _mapped_filter(attr)
          unless column_name
            msg = "Filtering by #{attr} is not allowed. No implementation mapping defined for it has been found \
              and there is not a model attribute with this name either.\n" \
              "Please add a mapping for #{attr} in the `filters_mapping` method of the appropriate Resource class"
            raise msg
          end          
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

      def _mapped_filter(name)
        target = self.class.filters_map[name]
        unless target
          if @model.attribute_names.include?(name.to_s)
            # Cache it in the filters mapping (to avoid later lookups), and return it.
            self.class.filters_map[name] = name
            target = name
          end
        end
        return target
      end

      # Private to try to funnel all column names through `generate` that restricts
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