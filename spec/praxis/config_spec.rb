require 'spec_helper'

describe Praxis::Config do
  subject(:config) do
    Praxis::Config.new
  end

  describe '#initialize' do
    it 'its type is a Struct type' do
      expect(config.attribute.type < Attributor::Struct).to be(true)
    end
    it 'has no value' do
      expect(config.get.attributes).to eq({})
    end
  end

  describe '#define' do
    context 'using a block' do
      context 'at the top level' do
        let(:key) { nil }
        before do
          config.define key do
            attribute :foo, String
          end
        end

        it 'defines a Struct-type configuration under :foo' do
          expect(config.attribute.attributes.keys).to eq [:foo]
        end

        context 'called again with new attributes' do
          before do
            config.define key do
              attribute :bar, String
            end
          end

          it 'adds the additional attributes to the Struct under :bar' do
            expect(config.attribute.attributes.keys).to eq %i[foo bar]
          end
        end
      end
      context 'for a sub-key' do
        let(:key) { :subkey }
        before do
          config.define key do
            attribute :inside, String
          end
        end
        it 'when it does not exist, it creates a whole new subkey Struct containing one key' do
          expect(config.attribute.attributes[:subkey].attributes.keys).to eq [:inside]
        end
        it 'when it already exists, will fail if it is of a different type' do
          expect do
            config.define key, Attributor::Hash
          end.to raise_error(/Incompatible type received for extending configuration key/)
        end
        it 'when it already exists, it add another subkey to the existing Struct' do
          config.define key do
            attribute :inside2, String
          end
          expect(config.attribute.attributes[:subkey].attributes.keys).to eq %i[inside inside2]
        end
      end
    end

    context 'using a direct type' do
      let(:config_type) { Attributor::Hash.of(key: String) }
      let(:config_opts) { {} }
      let(:config_key) { :foo }

      it 'it is not allowed if its for the top key' do
        expect  do
          config.define nil, config_type, **config_opts
        end.to raise_error(/You cannot define the top level configuration with a non-Struct type/)
      end

      before do
        config.define config_key, config_type, **config_opts
      end

      it 'sets the attribute to the defined type' do
        expect(config.attribute.attributes[config_key].type).to be(config_type)
      end
      it 'does not allow to redefine types that are not Structs' do
        expect do
          config.define config_key, Attributor::Hash
        end.to raise_error(Praxis::Exceptions::InvalidConfiguration,
                           /Incompatible type received for extending configuration key/)
      end
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
      expect { config.set({}) }.to raise_error(Praxis::Exceptions::ConfigValidation)
    end

    it 'fails when config cannot be loaded' do
      config.define do
        attribute :foo, Integer, required: true
      end
      expect { config.set({ foo: 'five' }) }.to raise_error(Praxis::Exceptions::ConfigLoad)
    end
  end
end
