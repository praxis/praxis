begin
  require 'link_header'
rescue LoadError
  warn "Praxis::Pagination requires the 'link_header' gem, which can not be found. " \
       "Please make sure it's in your Gemfile or installed in your system."
end
require 'praxis/extensions/pagination/pagination_params'
require 'praxis/extensions/pagination/ordering_params'
require 'praxis/extensions/pagination/pagination_handler'
require 'praxis/extensions/pagination/header_generator'

module Praxis
  module Extensions
    module Pagination
      extend ActiveSupport::Concern
      # This PaginatedController concern should be added to controllers that have actions that define the
      # pagination and order parameters so that calling `paginate( query: <base_query>, table: <main_table_name> )`
      # would handle all the required logic for paginating, ordering and generating the Link and TotalCount headers.
      # This assumes that the query object are chainable and based on ActiveRecord at the moment (although that logic)
      # can be easily applied to other chainable query proxies.
      #
      # Here's a simple example on how to use it for a fake Items controller
      # class Items < V1::Controllers::BaseController
      #   include Praxis::Controller
      #   include Praxis::Extensions::Rendering
      #   implements V1::Endpoints::Items
      #
      #   include Praxis::Extensions::Pagination
      #
      #   def index(filters: nil, pagination: nil, order: nil,  **_args)
      #     items = current_user.items.all
      #     items = handle_pagination( query: items)
      #
      #     display(items)
      #   end
      # end
      #
      # This code will properly add the right clauses to the final query based on the pagination strategy and ordering
      # and it will also generate the Link header with the appropriate relationships depending on the paging strategy.
      # When total_count is requested in the pagination a header with TotalCount will also be included.

      PaginationStruct = Struct.new(:paginator, :order, :total_count)

      included do
        after :action do |controller, _callee|
          if controller.response.status < 300
            # If this action has the pagination parameter defined,
            # calculate and set the pagination headers (Link header and possibly Total-Count)
            if controller._pagination.paginator
              headers = controller.build_pagination_headers(
                pagination: controller._pagination,
                current_url: controller.request.path,
                current_query_params: controller.request.query
              )
              controller.response.headers.merge! headers
            end
          end
        end
      end

      # Will set the typed paginator and order object into a controller ivar
      # This is lazily evaluated and memoized, so there's no need to only calculate things for actions that paginate/sort
      def _pagination
        return @_pagination if @_pagination

        pagination = {}
        attrs = request.action&.params&.type&.attributes
        pagination[:paginator] = request.params.pagination if attrs&.key? :pagination
        pagination[:order] = request.params.order if attrs&.key? :order

        @_pagination = PaginationStruct.new(pagination[:paginator], pagination[:order])
      end

      # Main entrypoint: Handles all pagination pieces
      # takes:
      # * the query to build from and the table
      # * the request (for link header generation)
      # * requires the _pagination variable to be there (set by this module) to return the pagination struct
      def _craft_pagination_query(query:, type: :active_record)
        handler_klass = \
          case type
          when :active_record
            ActiveRecordPaginationHandler
          when :sequel
            SequelPaginationHandler
          else
            raise "Attempting to use pagination but Active Record or Sequel gems found"
          end
 
        # Gather and save the count if required
        if _pagination.paginator&.total_count
          _pagination.total_count = handler_klass.count(query.dup)
        end
        
        query = handler_klass.order(query, _pagination.order)
        # Maybe this is a class instance instead of a class method?...(of the appropriate AR/Sequel type)...
        # self.class.paginate(query, table, _pagination)
        handler_klass.paginate(query, _pagination)
      end

      def build_pagination_headers(pagination:, current_url:, current_query_params:)
        links = if pagination.paginator.by
                  # We're assuming that the last element has a "symbol/string" field with the same name of the "by" pagination.
                  last_element = response.body.last
                  if last_element
                    last_value = last_element[pagination.paginator.by.to_sym] || last_element[pagination.paginator.by]
                  end
                  HeaderGenerator.build_cursor_headers(
                    paginator: pagination.paginator,
                    last_value: last_value,
                    total_count: pagination.total_count
                  )
                else
                  HeaderGenerator.build_paging_headers(
                    paginator: pagination.paginator,
                    total_count: pagination.total_count
                  )
                end

        HeaderGenerator.generate_headers(
          links: links,
          current_url: current_url,
          current_query_params: current_query_params,
          total_count: pagination.total_count
        )
      end

    end
  end
end
