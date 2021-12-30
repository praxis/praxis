# frozen_string_literal: true

require 'spec_helper'

describe Praxis::Application do
  context 'configuration' do
    subject(:app) do
      app = Class.new(Praxis::Application).instance

      config = Object.new
      def config.define(key = nil, type = Attributor::Struct, **opts, &block)
        [key, type, opts, block]
      end

      def config.get
        'gotconfig'
      end

      def config.set(config)
        config
      end
      app.instance_variable_set(:@config, config)
      app
    end

    describe '#config' do
      let(:myblock) { -> {} }
      it 'passes the block to config (and sets the right defaults)' do
        ret = app.config(&myblock)
        expect(ret).to eq([nil, Attributor::Struct, {}, myblock])
      end

      it 'passes the params and block to config' do
        ret = app.config(:key, Attributor::Hash, **{ option: :one }, &myblock)
        expect(ret).to eq([:key, Attributor::Hash, { option: :one }, myblock])
      end

      it 'gets config with no block given' do
        expect(app.config).to eq('gotconfig')
      end
    end

    describe '#config=' do
      it 'sets config' do
        ret = (app.config = 'someconfig')
        expect(ret).to eq 'someconfig'
      end
    end
  end

  context 'media type handlers' do
    subject { Class.new(Praxis::Application).instance }

    before do
      # don't actually bootload; we're merely running specs
      allow(subject.bootloader).to receive(:setup!).and_return(true)
      allow(subject.builder).to receive(:to_app).and_return(double('Rack app'))
    end

    describe '#handler' do
      let(:new_handler_name) { 'awesomesauce' }
      let(:new_handler_instance) { double('awesomesauce instance', generate: '', parse: {}) }
      let(:new_handler_class) { double('awesomesauce', new: new_handler_instance) }
      let(:bad_handler_instance) { double('bad handler instance', wokka: true, meep: false) }
      let(:bad_handler_class) { double('bad handler', new: bad_handler_instance) }

      context 'given a Class' do
        it 'instantiates and registers an instance' do
          expect(new_handler_class).to receive(:new)
          subject.handler new_handler_name, new_handler_class
        end
      end

      context 'given a non-Class' do
        it 'raises' do
          expect do
            subject.handler('awesomesauce', 'hi') # no instances allowed
          end.to raise_error(NoMethodError)

          expect do
            subject.handler('awesomesauce', ::Kernel) # no modules allowed
          end.to raise_error(NoMethodError)
        end
      end

      it 'overrides default handlers' do
        subject.handler 'json', new_handler_class
        subject.setup
        expect(subject.handlers['json']).to eq(new_handler_instance)
      end

      it 'ensures that handlers will work' do
        expect do
          subject.handler new_handler_name, bad_handler_class
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#setup' do
    subject { Class.new(Praxis::Application).instance }

    before do
      # don't actually bootload; we're merely running specs
      allow(subject.bootloader).to receive(:setup!).and_return(true)
      allow(subject.builder).to receive(:to_app).and_return(double('Rack app'))
    end

    it 'is idempotent' do
      expect(subject.builder).to receive(:to_app).once
      subject.setup
      subject.setup
    end

    it 'returns itself' do
      expect(subject.setup).to eq(subject)
      expect(subject.setup).to eq(subject)
    end
  end
end
