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
        %w[id name href description].each do |str|
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
