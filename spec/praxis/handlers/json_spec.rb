require 'spec_helper'

describe Praxis::Handlers::JSON do
  let(:dictionary) { { 'foo' => 1 } }
  let(:dictionary_json) { '{"foo":1}' }

  let(:array) { [1, 2, 3] }
  let(:array_json) { '[1,2,3]' }

  describe '#parse' do
    it 'handles dictionaries' do
      expect(subject.parse(dictionary_json)).to eq(dictionary)
    end

    it 'handles arrays' do
      expect(subject.parse(array_json)).to eq(array)
    end
  end

  # slightly cheesy: use #parse to test #generate by round-tripping everything
  describe '#generate' do
    it 'pretty-prints' do
      result = subject.generate({ 'foo' => 1 })
      expect(result).to include("\n")
      expect(result).to match(/^  /m)
    end

    it 'handles dictionaries' do
      expect(subject.parse(subject.generate(dictionary))).to eq(dictionary)
    end

    it 'handles arrays' do
      expect(subject.parse(subject.generate(array))).to eq(array)
    end
  end
end
