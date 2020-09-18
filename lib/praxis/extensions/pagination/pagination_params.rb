module Praxis
  module Extensions
    module Pagination
      class PaginationParams
        include Attributor::Type
        include Attributor::Dumpable

        # Pagination type that allows you to define a parameter type in an endpoint, including a DSL to restrict or configure
        # the pagination options of every single definition, and which will take care of parsing, coercing and validating the
        # pagination syntax below. It also takes care of generating the Link
        # and total count headers.
        # Pagination supports both cursor and page-based:
        # 1 - Page-based pagination (i.e., offset-limit based paging assuming an explicit or implicit ordering underneath)
        #   * it is done by using the 'page=<integer>' parameter, indicating which page number to output (based on a given page size)
        #   * setting the page size on a per-request basis can be achieved by setting the 'items=<integer>` parameter
        #   * example: `page=5,items=50`  (should return items 200-250 from the collection)
        # 2- Cursor-based pagination (paginating based on a field value)
        #   * it is done by using 'by=email', indicating the field name to use, and possibly using 'from=joe@example.com' to indicate
        #     after which values of the field to start listing (no 'from' values assume starting from the beginning).
        #   * the default page size can be overriden on a per-request basis as well with the 'items=<integer>` parameter
        #   #  example `by=email,from=joe@example.com,items=100`
        #
        # In either situation, one can also request to receive the total count of elements existing in the collection (pre-paging)
        # by using 'total_count=true'.
        #
        # Every pagination request will also receive a Link header (RFC 5988) properly populated with followable links.
        # When the 'total_count=true' parameter is used, a 'Total-Count' header will also be returned containing the total number
        # of existing results pre-pagination. Note that calculating the total count incurs in an extra DB query so it does have
        # performance implications

        ######################################################
        # DSL for definition pagination parameters in a defined filter.
        # Available options are:
        #
        # One can limit which fields the pagination (by cursor) can be allowed. Typically only indexed fields should
        # be allowed for performance reasons:
        #  * by_fields <Array of field names>  (if not provided, all fields are allowed)
        # One can limit the total maximum of items of the requested page size from the client can ask for:
        #  * max_items <integer> (there is a static upper limit to thie value set by the MAX_ITEMS constant)
        # One can set the default amount of items to return when not specified by the client
        #  * page_size <integer> (less or equal than max_items, if the max is set)
        # One can expicitly disallow either paging or cursor based pagination (by default both are allowed)
        # * disallow :paging | :cursor
        # One can set the default pagination mode when no :page, :by/:from parameters are passed in.
        # * default  <mode>: <value>  where mode can be :page or :by (and the value is an integer or a field name respectively)
        #
        # Here's a full example:
        # attribute :pagination, Types::PaginationParams.for(MediaTypes::Book) do
        #   by_fields :id, :name
        #   max_items 500
        #   page_size 50
        #   disallow :paging
        #   default by: :id
        # end
        class DSLCompiler < Attributor::DSLCompiler
          def by_fields(*fields)
            requested = fields.map(&:to_sym)
            non_matching = requested - target.media_type.attributes.keys
            unless non_matching.empty?
              raise "Error, you've requested to paginate by fields that do not exist in the mediatype!\n" \
              "The following #{non_matching.size} field/s do not exist in media type #{target.media_type.name} :\n" +
                    non_matching.join(',').to_s
            end
            target.fields_allowed = requested
          end

          def max_items(max)
            target.defaults[:max_items] = Integer(max)
          end

          def page_size(size)
            target.defaults[:page_size] = Integer(size)
          end

          def disallow(pagination_type)
            default_mode, default_value = target.defaults[:default_mode].first
            case pagination_type
            when :paging
              if default_mode == :page
                raise "Cannot disallow page-based pagination if you define a default pagination of:  page: #{default_value}"
              end
              target.defaults[:disallow_paging] = true
            when :cursor
              if default_mode == :by
                raise "Cannot disallow cursor-based pagination if you define a default pagination of:   by: #{default_value}"
              end
              target.defaults[:disallow_cursor] = true
            end
          end

          def default(spec)
            unless spec.is_a?(Hash) && spec.keys.size == 1 && [:by, :page].include?(spec.keys.first)
              raise "'default' syntax for pagination takes exactly one key specification. Either by: <:fieldname> or page: <num>" \
                    "#{spec} is invalid"
            end
            mode, value = spec.first
            def_mode = case mode
                       when :by
                         if target.fields_allowed && !target.fields_allowed&.include?(value)
                           raise "Error setting default pagination. Field #{value} is not amongst the allowed fields."
                         end
                         if target.defaults[:disallow_cursor]
                           raise "Cannot define a default pagination that is cursor based, if cursor-based pagination is disallowed."
                         end
                         { by: value }
                       when :page
                         unless value.is_a?(Integer)
                           raise "Error setting default pagination. Initial page should be a integer (but got #{value})"
                         end
                         if target.defaults[:disallow_paging]
                           raise "Cannot define a default pagination that is page-based, if page-based pagination is disallowed."
                         end
                         { page: value }
                       end
            target.defaults[:default_mode] = def_mode
          end
        end

        # Configurable DEFAULTS
        @max_items = nil # Unlimited by default (since it's not possible to set it to nil for now from the app)
        @default_page_size = 100
        @paging_default_mode = { page: 1 }
        @disallow_paging_by_default = false
        @disallow_cursor_by_default = false

        def self.max_items(newval = nil)
          newval ? @max_items = newval : @max_items
        end

        def self.default_page_size(newval = nil)
          newval ? @default_page_size = newval : @default_page_size
        end

        def self.disallow_paging_by_default(newval = nil)
          newval ? @disallow_paging_by_default = newval : @disallow_paging_by_default
        end

        def self.disallow_cursor_by_default(newval = nil)
          newval ? @disallow_cursor_by_default = newval : @disallow_cursor_by_default
        end

        def self.paging_default_mode(newval = nil)
          if newval
            unless newval.respond_to?(:keys) && newval.keys.size == 1 && [:by, :page].include?(newval.keys.first)
              raise "Error setting paging_default_mode, value must be a hash with :by or :page keys"
            end
            @paging_default_mode = newval
          end
          @paging_default_mode
        end

        # Abstract class, which needs to be used by subclassing it through the .for method, to link it to a particular
        # MediaType, so that the field name checking and value coercion can be performed
        class << self
          attr_reader :media_type
          attr_reader :defaults
          attr_accessor :fields_allowed

          def for(media_type, **_opts)
            unless media_type < Praxis::MediaType
              raise ArgumentError, "Invalid type: #{media_type.name} for Paginator. " \
                "Must be a subclass of MediaType"
            end

            ::Class.new(self) do
              @media_type = media_type
              @defaults = {
                page_size: PaginationParams.default_page_size,
                max_items: PaginationParams.max_items,
                disallow_paging: PaginationParams.disallow_paging_by_default,
                disallow_cursor: PaginationParams.disallow_cursor_by_default,
                default_mode: PaginationParams.paging_default_mode
              }
            end
          end
        end

        def self.native_type
          self
        end

        def self.name
          'Extensions::Pagination::PaginationParams'
        end

        def self.display_name
          'Paginator'
        end

        def self.family
          'string'
        end

        def self.constructable?
          true
        end

        def self.construct(pagination_definition, **options)
          return self if pagination_definition.nil?

          DSLCompiler.new(self, options).parse(*pagination_definition)
          self
        end

        attr_reader :by
        attr_reader :from
        attr_reader :items
        attr_reader :page
        attr_reader :total_count

        def self.example(_context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
          fields = if media_type
                     mt_example = media_type.example
                     simple_attrs = media_type.attributes.select do |_k, attr|
                       attr.type == Attributor::String || attr.type == Attributor::Integer
                     end

                     selectable = mt_example.object.keys & simple_attrs.keys
                     by = selectable.sample(1).first
                     from = media_type.attributes[by].example(parent: mt_example)
                     # Make sure to encode the value of the from, as it can contain commas and such
                     from = CGI.escape(from) if from.is_a? String
                     "by=#{by},from=#{from},items=#{defaults[:page_size]}"
                   else
                     "by=id,from=20,items=100"
                   end
          load(fields)
        end

        def self.validate(value, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute = nil)
          instance = load(value, context)
          instance.validate(context)
        end

        CLAUSE_REGEX = /(?<type>[^=]+)=(?<value>.+)$/
        def self.load(paginator, _context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
          return paginator if paginator.is_a?(native_type) || paginator.nil?
          parsed = {}
          unless paginator.nil?
            parsed = paginator.split(',').each_with_object({}) do |paginator_string, hash|
              match = CLAUSE_REGEX.match(paginator_string)
              case match[:type].to_sym
              when :page
                hash[:page] = Integer(match[:value])
              when :by
                hash[:by] = match[:value]
              when :from
                hash[:from] = match[:value]
              when :total_count
                hash[:total_count] = (match[:value] != 'false') # unless explicitly set to false, we'll take it as true...
              when :items
                hash[:items] = Integer(match[:value])
              else
                raise "Error loading pagination parameters: unknown parameter with name '#{match[:type]}' found"
              end
            end
          end

          parsed[:items] = defaults[:page_size] unless parsed.key?(:items)
          parsed[:from] = coerce_field(parsed[:by], parsed[:from]) if parsed.key?(:from)

          # If no by/from or page specified, we're gonna apply the defaults
          unless parsed.key?(:by) || parsed.key?(:from) || parsed.key?(:page)
            mode, value = defaults[:default_mode].first
            case mode
            when :by
              parsed[:by] = value
            when :page
              parsed[:page] = value
            end
          end

          new(parsed)
        end

        def self.dump(value, **_opts)
          load(value).dump
        end

        def self.describe(_root = false, example: nil)
          hash = super

          hash[:fields_allowed] = fields_allowed if fields_allowed
          if defaults
            hash[:max_items]    = defaults[:max_items]
            hash[:page_size]    = defaults[:page_size]
            hash[:default_mode] = defaults[:default_mode]

            disallowed = []
            disallowed << :paging if defaults[:disallow_paging] == true
            disallowed << :cursor if defaults[:disallow_cursor] == true
            hash[:disallowed] = disallowed unless disallowed.empty?
          end

          hash
        end

        # Silently ignore if the fiels does not exist...let's let the validation check it instead
        def self.coerce_field(name, value)
          if media_type&.attributes
            attrs = media_type&.attributes || {}
            attribute = attrs[name.to_sym]
            attribute.type.load(value) if attribute
          else
            value
          end
        end

        # Instance methods
        def initialize(parsed)
          @by = parsed[:by]
          @from = parsed[:from]
          @items = parsed[:items]
          @page = parsed[:page]
          @total_count = parsed[:total_count]
        end

        def validate(_context = Attributor::DEFAULT_ROOT_CONTEXT) # rubocop:disable Metrics/PerceivedComplexity
          errors = []

          if page
            if self.class.defaults[:disallow_paging]
              errors << "Page-based pagination is disallowed (i.e., using 'page=' parameter)"
            end
          elsif self.class.defaults[:disallow_cursor]
            errors << "Cursor-based pagination is disallowed (i.e., using 'by=' or 'from=' parameter)"
          end

          if page && page <= 0
            errors << "Page parameter cannot be zero or negative! (got: #{parsed.page})"
          end

          if items && (items <= 0 || ( self.class.defaults[:max_items] && items > self.class.defaults[:max_items]) )
            errors << "Value of 'items' is invalid (got: #{items}). It must be positive, and smaller than the maximum amount of items per request (set to #{self.class.defaults[:max_items]})"
          end

          if page && (by || from)
            errors << "Cannot specify the field to use and its start value to paginate from when using a fix pager (i.e., `by` and/or `from` params are not compabible with `page`)"
          end

          if by && self.class.fields_allowed && !self.class.fields_allowed.include?(by.to_sym)
            errors << if self.class.media_type.attributes.key?(by.to_sym)
                        "Paginating by field \'#{by}\' is disallowed"
                      else
                        "Paginating by field \'#{by}\' is not possible as this field does not exist in "\
                        "media type #{self.class.media_type.name}"
                      end
          end
          errors
        end

        # Dump back string parseable form
        def dump
          str = if @page
                  "page=#{@page}"
                else
                  s = "by=#{@by}"
                  s += ",from=#{@from}" if @from
                end
          str += ",items=#{items}" if @items
          str += ",total_count=true" if @total_count
          str
        end
      end
    end
  end
end

# Alias it to a much shorter and sweeter name in the Types namespace.
module Praxis
  module Types
    PaginationParams = Praxis::Extensions::Pagination::PaginationParams
  end
end
