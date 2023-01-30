# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../support/spec_media_types'

describe Praxis::Extensions::Pagination::OrderingParams do
  let(:blog_ordering_type) { Praxis::Types::OrderingParams.for(Blog) }
  
  context '#validate' do
    context 'full enforcement and nested relationships' do
      let(:order_attr) do
        Attributor::Attribute.new(blog_ordering_type) do
          by_fields :id, 'recent_posts.title', 'recent_posts.author.first'
          enforce_for :all
        end
      end
      it 'works for allowed fields' do
        ['id', 'recent_posts.title', 'recent_posts.author.first'].each do |str|
          expect(order_attr.load(str).validate).to be_empty
        end
      end
      it 'enforces all components' do
        # Allowed at any position
        expect(order_attr.load('recent_posts.title,id').validate).to be_empty
        # Not allowed even in second position if it isn't on the list
        expect(order_attr.load('recent_posts.title,name').validate).to_not be_empty
      end
      it 'fails for valid but unallowed fields' do
        ['name', 'recent_posts.id'].each do |str|
          expect(order_attr.load(str).validate).to_not be_empty
        end
      end
      it 'fails for invalid fields' do
        ['nothing', 'badassoc.none'].each do |str|
          expect(order_attr.load(str).validate).to_not be_empty
        end
      end
    end
    context 'first-only enforcement' do
      let(:order_attr) do
        Attributor::Attribute.new(blog_ordering_type) do
          by_fields :id, 'recent_posts.title'
          enforce_for :first
        end
      end
      it 'enforces only first components' do
        # It does not allow 'name' if it is in the first position
        expect(order_attr.load('name,recent_posts.title').validate).to_not be_empty
        # Allows 'name' if it is not in the first position
        expect(order_attr.load('recent_posts.title,name').validate).to be_empty
      end
    end
    context 'default enforcement' do
      let(:order_attr) do
        Attributor::Attribute.new(blog_ordering_type)
      end
      it 'allows any attribute of the mediatype' do
        ['id', 'name', 'href', 'description'].each do |str|
          expect(order_attr.load(str).validate).to be_empty
        end
      end
      it 'enforces only first components' do
        # It allows non-defined field in second position
        expect(order_attr.load('name,recent_posts.title').validate).to be_empty
        # It does not allow non-defined field in first position
        expect(order_attr.load('recent_posts.title,name').validate).to_not be_empty
      end
    end
  end
end

# require_relative '../support/spec_resources_active_model'
# require 'praxis/extensions/pagination'

# class Book < Praxis::MediaType
#   attributes do
#     attribute :id, Integer
#     attribute :simple_name, String
#     attribute :category_uuid, String
#   end
# end
# Book.finalize!
# BookPaginationParamsAttribute = Attributor::Attribute.new(Praxis::Types::PaginationParams.for(Book)) do
#   max_items 3
#   page_size 2
#   #   disallow :paging
#   default by: :id
# end

# BookOrderingParamsAttribute = Attributor::Attribute.new(Praxis::Types::OrderingParams.for(Book)) do
#   enforce_for :all
# end

# describe Praxis::Extensions::Pagination::ActiveRecordPaginationHandler do
#   shared_examples 'sorts_the_same' do |op, expected|
#     let(:order_params) { BookOrderingParamsAttribute.load(op) }
#     it do
#       loaded_ids = subject.all.map(&:id)
#       expected_ids = expected.all.map(&:id)
#       expect(loaded_ids).to eq(expected_ids)
#     end
#   end

#   shared_examples 'paginates_the_same' do |par, expected|
#     let(:paginator_params) { BookPaginationParamsAttribute.load(par) }
#     it do
#       loaded_ids = subject.all.map(&:id)
#       expected_ids = expected.all.map(&:id)
#       expect(loaded_ids).to eq(expected_ids)
#     end
#   end

#   let(:query) { ActiveBook.includes(:author) }
#   let(:table) { ActiveBook.table_name }
#   let(:paginator_params) { nil }
#   let(:order_params) { nil }
#   let(:pagination) do
#     Praxis::Extensions::Pagination::PaginationStruct.new(paginator_params, order_params)
#   end

#   context '.paginate' do
#     let(:selectors) { [] } # ??!!!!
#     subject { described_class.paginate(query, pagination, selectors) }

#     context 'empty struct' do
#       let(:paginator_params) { nil }

#       it 'does not change the query with an empty struct' do
#         expect(subject).to be(query)
#       end
#     end

#     context 'page-based' do
#       it_behaves_like 'paginates_the_same', 'page=1,items=3',
#                       ::ActiveBook.limit(3)
#       it_behaves_like 'paginates_the_same', 'page=2,items=3',
#                       ::ActiveBook.offset(3).limit(3)
#     end

#     context 'page-based with defaults' do
#       it_behaves_like 'paginates_the_same', '',
#                       ::ActiveBook.offset(0).limit(2)
#       it_behaves_like 'paginates_the_same', 'page=2',
#                       ::ActiveBook.offset(2).limit(2)
#     end

#     context 'cursor-based' do
#       it_behaves_like 'paginates_the_same', 'by=id,items=3',
#                       ::ActiveBook.limit(3).order(id: :asc)
#       it_behaves_like 'paginates_the_same', 'by=id,from=1000,items=3',
#                       ::ActiveBook.where('id > 1000').limit(3).order(id: :asc)
#       it_behaves_like 'paginates_the_same', 'by=simple_name,from=Book1000,items=3',
#                       ::ActiveBook.where("simple_name > 'Book1000'").limit(3).order(simple_name: :asc)
#     end

#     context 'cursor-based with defaults' do
#       it_behaves_like 'paginates_the_same', '',
#                       ::ActiveBook.limit(2).order(id: :asc)
#       it_behaves_like 'paginates_the_same', 'by=id,from=1000',
#                       ::ActiveBook.where('id > 1000').limit(2).order(id: :asc)
#     end

#     context 'including order' do
#       let(:order_params) { BookOrderingParamsAttribute.load(op_string) }

#       context 'when compatible with cursor' do
#         let(:op_string) { 'id' }
#         # Compatible cursor field
#         it_behaves_like 'paginates_the_same', 'by=id,items=3',
#                         ::ActiveBook.limit(3).order(id: :asc)
#       end

#       context 'when incompatible with cursor' do
#         let(:op_string) { 'id' }
#         let(:paginator_params) { BookPaginationParamsAttribute.load('by=simple_name,items=3') }
#         it do
#           expect { subject.all }.to raise_error(described_class::PaginationException, /is incompatible with pagination/)
#         end
#       end
#     end
#   end

#   context '.order' do
#     let(:selectors) { [] } # ???
#     subject { described_class.order(query, pagination.order, selectors) }

#     it 'does not change the query with an empty struct' do
#       expect(subject).to be(query)
#     end

#     it_behaves_like 'sorts_the_same', 'simple_name',
#                     ::ActiveBook.order(simple_name: :asc)
#     it_behaves_like 'sorts_the_same', '-simple_name',
#                     ::ActiveBook.order(simple_name: :desc)
#     it_behaves_like 'sorts_the_same', '-simple_name,id',
#                     ::ActiveBook.order(simple_name: :desc, id: :asc)
#     it_behaves_like 'sorts_the_same', '-simple_name,-id',
#                     ::ActiveBook.order(simple_name: :desc, id: :desc)

#     ActiveRecord::Base.logger = Logger.new(STDOUT)
#     it_behaves_like 'sorts_the_same', '-author.name',
#                     ::ActiveBook.joins(:author).references(:author).order('active_authors.name': :desc)
#   end
# end
