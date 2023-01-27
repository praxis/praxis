# frozen_string_literal: true

require 'spec_helper'
require_relative 'praxis/extensions/support/spec_resources_active_model'

describe 'Functional specs with connected DB' do
  def app
    Praxis::Application.instance
  end
  let(:parsed_response) { JSON.parse(subject.body, symbolize_names: true) }
  context 'index' do
    let(:filters_q) { '' }
    let(:fields_q) { '' }
    subject do
      get '/api/books', api_version: '1.0', fields: fields_q, filters: filters_q
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
