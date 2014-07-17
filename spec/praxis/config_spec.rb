require 'spec_helper'

describe Praxis::Config do
  subject(:config) do
    Praxis::Config.new
  end

  describe '#initialize' do
    it 'has no attribute' do
      expect(config.attribute.attributes).to eq({})
    end

    it 'has no values' do
      expect(config.get).to be(nil)
    end
  end

  describe '#define' do
    it 'defines configuration' do
      config.define do
        attribute :foo, String
      end
      expect(config.attribute.attributes.keys).to eq [:foo]
    end
  end

  describe '#set' do
    it 'sets configuration values' do
      config.define do
        attribute :foo, String
      end
      config.set({ foo: 'bar' })
      expect(config.get.foo).to eq 'bar'
    end

    it 'fails when config does not validate' do
      config.define do
        attribute :foo, String, required: true
      end
      expect{ config.set({}) }.to raise_error(
        Praxis::Exceptions::ConfigValidationException)
    end

    it 'fails when config cannot be loaded' do
      config.define do
        attribute :foo, Integer, required: true
      end
      expect{ config.set({foo: 'five'}) }.to raise_error(
        Praxis::Exceptions::ConfigLoadException)
    end
  end
end
