# frozen_string_literal: true

require 'spec_helper'
ActiveRecord::Base.logger = Logger.new(STDOUT)
describe 'Functional specs with connected DB' do
  def app
    Praxis::Application.instance
  end
  let(:parsed_response) { JSON.parse(subject.body, symbolize_names: true) }
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

        context 'TESTING!!!' do
          let(:order_q) { '-author.name' }
          let(:filters_q) { 'author.id=1&tags.taggings.tag.name=red' }
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
          # let(:filters_q) { 'author!' }
          let(:filters_q) { 'id=1&author!&author.name!&tags.name=red' }
          it { expect(subject).to be_successful }
        end
      end
      pending 'using a base query that has direct joins on the same table...' do
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
  end
end
