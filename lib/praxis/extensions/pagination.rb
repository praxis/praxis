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
      # pagination and order parameters so that one can call the domain model to craft the query
      # `domain_model.craft_pagination_query(base_query, pagination: _pagination)`
      # This will handle all the required logic for paginating, ordering and generating the Link and TotalCount headers.
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
      #     domain_model = self.media_type.domain_model
      #     items = domain_model.craft_pagination_query( query: items, pagination: _pagination)
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
