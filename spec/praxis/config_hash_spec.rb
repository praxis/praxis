# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Praxis::ConfigHash do
  subject(:instance) { Praxis::ConfigHash.new(hash, &block) }
  let(:hash) { { one: ['existing'], two: 'dos' } }
  let(:block) do
    proc { 'abc' }
  end

  context 'initialization' do
    it 'saves the passed hash' do
      expect(subject.hash).to be(hash)
    end
  end

  context '.from' do
    subject(:instance) { Praxis::ConfigHash.from(hash, &block) }
    it 'returns an instance' do
      expect(subject).to be_kind_of(Praxis::ConfigHash)
      expect(subject.hash).to be(hash)
    end
  end

  context '#to_hash' do
    let(:block) do
      proc { hash['i_was'] = 'here' }
    end
    it 'evaluates the block and returns the resulting hash' do
      expect(subject.to_hash).to eq(subject.hash)
      expect(subject.hash['i_was']).to eq('here')
    end
  end

  context '#method_missing' do
    context 'when keys do not exist in the hash key' do
      it 'sets a single value to the hash' do
        subject.some_name 'someval'
        expect(subject.hash[:some_name]).to eq('someval')
      end
      it 'sets a multiple values to the hash key' do
        subject.some_name 'someval', 'other1', 'other2'
        expect(subject.hash[:some_name]).to include('someval', 'other1', 'other2')
      end
    end
    context 'when keys already exist in the hash key' do
      it 'adds one value to the hash' do
        subject.one 'newval'
        expect(subject.hash[:one]).to match_array(%w[existing newval])
      end
      it 'adds multiple values to the hash key' do
        subject.one 'newval', 'other1', 'other2'
        expect(subject.hash[:one]).to match_array(%w[existing newval other1 other2])
      end
      context 'when passing a value and a block' do
        let(:my_block) { proc {} }
        it 'adds the tuple to the hash key' do
          subject.one 'val', &my_block
          expect(subject.hash[:one]).to include(['val', my_block])
        end
      end
    end
  end
end
