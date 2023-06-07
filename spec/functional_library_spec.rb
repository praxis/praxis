# frozen_string_literal: true

require 'spec_helper'

describe 'Functional specs for books with connected DB' do
  def app
    Praxis::Application.instance
  end
  let(:parsed_response) { JSON.parse(subject.body, symbolize_names: true) }
  context 'books' do
    context 'index' do
      let(:filters_q) { '' }
      let(:fields_q) { '' }
      let(:order_q) { '' }
      subject do
        get '/api/books', api_version: '1.0', fields: fields_q, filters: filters_q, order: order_q
      end

      context 'all books' do
        it 'is successful' do
          expect(subject).to be_successful
          expect(subject.headers['Content-Type']).to eq('application/vnd.acme.book; type=collection')
          expect(parsed_response.size).to eq ActiveBook.count
        end
      end

      context 'with deep fields including a group' do
        let(:fields_q) { 'id,name,author{name,books{name}},tags,grouped{name,moar_tags}' }
        it 'is successful' do
          expect(subject).to be_successful
          first_book = parsed_response.first
          expect(first_book.keys).to match_array(%i[id name author tags grouped])
          expect(first_book[:author].keys).to match_array(%i[name books])
          expect(first_book[:grouped].keys).to match_array(%i[name moar_tags])
          expect(first_book[:grouped][:name]).to eq(first_book[:name])
          # grouped.moar_tags is exactly the same result as tags, but tucked in a group with a different name
          expect(first_book[:grouped][:moar_tags]).to eq(first_book[:tags])
        end
      end

      context 'with deep filters' do
        let(:filters_q) { 'author.name=author*' }
        it 'is successful' do
          expect(subject).to be_successful
          expect(parsed_response.size).to eq ActiveBook.joins(:author).where('active_authors.name LIKE "author%"').count
        end
      end
      context 'with more deep filters' do
        let(:filters_q) { 'tags.name=green' }
        it 'is successful' do
          expect(subject).to be_successful
          num_books_with_green_tags = ActiveBook.joins(:tags).where('active_tags.name': 'green').count
          expect(num_books_with_green_tags).to be > 0
          expect(parsed_response.size).to eq num_books_with_green_tags
        end
      end

      context 'with ordering' do
        context 'by direct attribute' do
          let(:order_q) { '-id' }
          it 'is successful' do
            expect(subject).to be_successful
            expect(parsed_response.map { |book| book[:id] }).to eq ActiveBook.distinct.order('id DESC').pluck(:id)
          end
        end
        context 'by nested attribute (but without any fields or filter using the attribute)' do
          let(:order_q) { '-author.name' }
          it 'is successful' do
            expect(subject).to be_successful
            ids = ActiveBook.distinct.left_outer_joins(:author).order('active_authors.name DESC').pluck(:id)

            expect(parsed_response.map { |book| book[:id] }).to eq ids
          end
        end
        context 'combined with filters' do
          context 'by nested attribute (with fields using the same association, but not the same leaf)' do
            let(:order_q) { '-author.name' }
            let(:fields_q) { 'id,author{id}' }
            it { expect(subject).to be_successful }
          end

          context 'by nested attribute (with a filter using the same association, but not the same leaf)' do
            let(:order_q) { '-author.name' }
            let(:filters_q) { 'author.id=1' }
            it { expect(subject).to be_successful }
          end

          context 'by nested attribute (with a filter using the same association AND the same leaf)' do
            let(:order_q) { '-author.name' }
            let(:filters_q) { 'author.name=Author1' }
            it { expect(subject).to be_successful }
          end

          context 'Using ! on a leaf also makes the order use the alias' do
            let(:order_q) { '-author.name' }
            let(:filters_q) { 'author.name!' }
            it { expect(subject).to be_successful }
          end

          context 'Using ! on an overlapping association also makes the order use the alias' do
            let(:order_q) { '-author.name' }
            let(:filters_q) { 'id=1&author!&author.name!&tags.name=red' }
            it { expect(subject).to be_successful }
          end
        end
      end
    end

    context 'show' do
      let(:fields_q) { '' }
      subject do
        get '/api/books/1', api_version: '1.0', fields: fields_q
      end
      it 'is successful' do
        expect(subject).to be_successful
        expect(parsed_response[:name]).to eq ActiveBook.find_by(id: 1).simple_name
      end

      context 'with grouped attributes' do
        let(:fields_q) { 'id,grouped{id,name}' }
        it 'is successful' do
          expect(subject).to be_successful
          model = ActiveBook.find_by(id: 1)
          expect(parsed_response[:id]).to eq model.id
          expect(parsed_response[:grouped]).to eq({ id: model.id, name: model.simple_name })
        end

        context 'it does not invoke the ones that are not rendered' do
          let(:fields_q) { 'id,grouped{id}' }
          it 'is successful' do
            expect(subject).to be_successful
          end
        end
      end

      context 'with protected attributes' do
        let(:fields_q) { 'id,special,multi' }
        before do
          expect(::Book.attributes[:special].options[:displayable]).to eq(['special#read'])
          expect(::Book.attributes[:multi].options[:displayable]).to eq(['special#read','normal#read'])
        end
        context 'using the API' do
          context 'when the user has the privilege for an attribute' do
            before { allow(::BaseClass).to receive(:current_user_privs).and_return(['special#read']) }
            it 'renders it' do
              expect(parsed_response.keys).to include(:special)
              expect(parsed_response.keys).to_not include(:multi)
            end
          end

          context 'when the user does not have the privilege' do
            before { allow(::BaseClass).to receive(:current_user_privs).and_return(['anotherpriv!']) }
            it 'does not render it' do
              expect(parsed_response.keys).to_not include(:special)
              expect(parsed_response.keys).to_not include(:multi)
            end
          end

          context 'when the user has multiple privilege for multiple attributes' do
            before { allow(::BaseClass).to receive(:current_user_privs).and_return(['special#read','normal#read']) }
            it 'renders both' do
              expect(parsed_response.keys).to include(:special,:multi)
            end
          end
        end
      end
    end
  end

  context 'authors (which have a base query that joins itself)' do
    let(:filters_q) { '' }
    let(:fields_q) { '' }
    let(:order_q) { '' }
    let(:pagination_q) { '' }
    subject do
      get '/api/authors', api_version: '1.0', fields: fields_q, filters: filters_q, order: order_q, pagination: pagination_q
    end

    context 'all authors' do
      # Authors have a base query that restricts authors whom have books that start with 'book' and that reach authors with id > 0
      let(:base_query) do
        ActiveAuthor.joins(books: :author).where('active_books.simple_name LIKE ?', 'book%').where('authors_active_books.id > ?', 0)
      end
      context 'using any filters/order/pagination attributes works, since they have been defined empty in the block definition' do
        it 'is successful' do
          expect(subject).to be_successful
          expect(subject.headers['Content-Type']).to eq('application/vnd.acme.author; type=collection')

          expect(parsed_response.size).to eq base_query.count
        end
        context 'ordering' do
          context 'using direct attributes' do
            let(:order_q) { '-name,id' }
            it { expect(subject).to be_successful }
          end
          context 'using nested attributes' do
            let(:order_q) { '-name,books.name' }
            it 'is successful' do
              expect(subject).to be_successful
              ids = base_query.order('active_authors.name DESC', 'active_books.simple_name DESC').pluck(:id)

              expect(parsed_response.map { |book| book[:id] }).to eq ids
            end
          end
        end
        context 'filtering and sorting' do
          context 'using the same tables, including the base query one' do
            let(:order_q) { '-name,books.author.name' }
            let(:filters_q) { 'books.name!' }
            let(:fields_q) { 'id,books{name}' }
            it 'is successful' do
              expect(subject).to be_successful
              ids = base_query.order('active_authors.name DESC', 'active_books.simple_name DESC').pluck(:id)

              expect(parsed_response.map { |book| book[:id] }).to eq ids
            end
          end
        end
        context 'with page-based pagination' do
          context 'using the same tables, including the base query one' do
            let(:order_q) { '-name,books.author.name' }
            let(:filters_q) { 'books.name!' }
            let(:fields_q) { 'id,books{name}' }
            let(:pagination_q) { 'page=1,items=2' }
            it 'is successful' do
              expect(subject).to be_successful
              ids = base_query.order('active_authors.name DESC', 'active_books.simple_name DESC').limit(2).pluck(:id)

              expect(parsed_response.map { |book| book[:id] }).to eq ids
            end
          end
        end
        context 'with cursor-based pagination' do
          context 'using the same tables, including the base query one' do
            let(:order_q) { '-name,books.author.name' }
            let(:filters_q) { 'books.name!' }
            let(:fields_q) { 'id,books{name}' }
            let(:pagination_q) { 'by=name,items=2' }
            it 'is successful' do
              expect(subject).to be_successful
              ids = base_query.order('active_authors.name DESC', 'active_books.simple_name DESC').limit(2).pluck(:id)

              expect(parsed_response.map { |book| book[:id] }).to eq ids
            end
          end
        end
      end
    end
  end
end