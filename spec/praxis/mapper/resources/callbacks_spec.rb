# frozen_string_literal: true

require 'spec_helper'

describe Praxis::Mapper::Resources::Callbacks do
  context 'callbacks' do
    let(:double_model) do
      SimpleModel.new(before_count: 0, after_count: 0, around_count: 0, name: '', force: false)
    end
    let(:resource) { SimpleResource.new(double_model) }
    context 'using functions with args and kwargs' do
      subject { resource.change_name('hi', force: true)}
      it 'before' do
        expect(subject.record.before_count).to eq(1) #1 before hook
      end
      it 'after' do
        expect(subject.record.after_count).to eq(1) #1 after hook
      end
      it 'around' do
        # 50, just for the only filter
        expect(subject.record.around_count).to eq(50)
      end
      after do
        # one for the before, the around filter, the actual method and the after filter
        expect(subject.record.name).to eq('hi-hi-hi-hi')
        expect(subject.record.force).to be_truthy
      end
    end

    context 'using functions with only kwargs' do
      subject { resource.update!(number: 1000)}
      it 'before' do
        expect(subject.record.before_count).to eq(1) # 1 before hook
      end
      it 'after' do
        expect(subject.record.after_count).to eq(1) # 1 after hook
      end
      it 'around' do
        # 1000 for the orig update+1 from before_count + 50+100 for the 2 around filters
        expect(subject.record.around_count).to eq(1151)
      end
    end
  end
end
