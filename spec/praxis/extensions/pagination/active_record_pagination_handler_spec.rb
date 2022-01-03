# frozen_string_literal: true

require 'spec_helper'

require_relative '../support/spec_resources_active_model'
require 'praxis/extensions/pagination'

class Book < Praxis::MediaType
  attributes do
    attribute :id, Integer
    attribute :simple_name, String
    attribute :category_uuid, String
  end
end
Book.finalize!
BookPaginationParamsAttribute = Attributor::Attribute.new(Praxis::Types::PaginationParams.for(Book)) do
  max_items 3
  page_size 2
  #   disallow :paging
  default by: :id
end

BookOrderingParamsAttribute = Attributor::Attribute.new(Praxis::Types::OrderingParams.for(Book)) do
  enforce_for :all
end

describe Praxis::Extensions::Pagination::ActiveRecordPaginationHandler do
  shared_examples 'sorts_the_same' do |op, expected|
    let(:order_params) { BookOrderingParamsAttribute.load(op) }
    it do
      loaded_ids = subject.all.map(&:id)
      expected_ids = expected.all.map(&:id)
      expect(loaded_ids).to eq(expected_ids)
    end
  end

  shared_examples 'paginates_the_same' do |par, expected|
    let(:paginator_params) { BookPaginationParamsAttribute.load(par) }
    it do
      loaded_ids = subject.all.map(&:id)
      expected_ids = expected.all.map(&:id)
      expect(loaded_ids).to eq(expected_ids)
    end
  end

  let(:query) { ActiveBook }
  let(:table) { ActiveBook.table_name }
  let(:paginator_params) { nil }
  let(:order_params) { nil }
  let(:pagination) do
    Praxis::Extensions::Pagination::PaginationStruct.new(paginator_params, order_params)
  end

  context '.paginate' do
    subject { described_class.paginate(query, pagination) }

    context 'empty struct' do
      let(:paginator_params) { nil }

      it 'does not change the query with an empty struct' do
        expect(subject).to be(query)
      end
    end

    context 'page-based' do
      it_behaves_like 'paginates_the_same', 'page=1,items=3',
                      ::ActiveBook.limit(3)
      it_behaves_like 'paginates_the_same', 'page=2,items=3',
                      ::ActiveBook.offset(3).limit(3)
    end

    context 'page-based with defaults' do
      it_behaves_like 'paginates_the_same', '',
                      ::ActiveBook.offset(0).limit(2)
      it_behaves_like 'paginates_the_same', 'page=2',
                      ::ActiveBook.offset(2).limit(2)
    end

    context 'cursor-based' do
      it_behaves_like 'paginates_the_same', 'by=id,items=3',
                      ::ActiveBook.limit(3).order(id: :asc)
      it_behaves_like 'paginates_the_same', 'by=id,from=1000,items=3',
                      ::ActiveBook.where('id > 1000').limit(3).order(id: :asc)
      it_behaves_like 'paginates_the_same', 'by=simple_name,from=Book1000,items=3',
                      ::ActiveBook.where("simple_name > 'Book1000'").limit(3).order(simple_name: :asc)
    end

    context 'cursor-based with defaults' do
      it_behaves_like 'paginates_the_same', '',
                      ::ActiveBook.limit(2).order(id: :asc)
      it_behaves_like 'paginates_the_same', 'by=id,from=1000',
                      ::ActiveBook.where('id > 1000').limit(2).order(id: :asc)
    end

    context 'including order' do
      let(:order_params) { BookOrderingParamsAttribute.load(op_string) }

      context 'when compatible with cursor' do
        let(:op_string) { 'id' }
        # Compatible cursor field
        it_behaves_like 'paginates_the_same', 'by=id,items=3',
                        ::ActiveBook.limit(3).order(id: :asc)
      end

      context 'when incompatible with cursor' do
        let(:op_string) { 'id' }
        let(:paginator_params) { BookPaginationParamsAttribute.load('by=simple_name,items=3') }
        it do
          expect { subject.all }.to raise_error(described_class::PaginationException, /is incompatible with pagination/)
        end
      end
    end
  end

  context '.order' do
    subject { described_class.order(query, pagination.order) }

    it 'does not change the query with an empty struct' do
      expect(subject).to be(query)
    end

    it_behaves_like 'sorts_the_same', 'simple_name',
                    ::ActiveBook.order(simple_name: :asc)
    it_behaves_like 'sorts_the_same', '-simple_name',
                    ::ActiveBook.order(simple_name: :desc)
    it_behaves_like 'sorts_the_same', '-simple_name,id',
                    ::ActiveBook.order(simple_name: :desc, id: :asc)
    it_behaves_like 'sorts_the_same', '-simple_name,-id',
                    ::ActiveBook.order(simple_name: :desc, id: :desc)
  end
end
