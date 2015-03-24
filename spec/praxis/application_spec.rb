require 'spec_helper'

describe Praxis::Application do
  context 'configuration' do
    subject(:app) do
      app = Class.new(Praxis::Application).instance

      config = Object.new
      def config.define(key=nil, type=Attributor::Struct, **opts, &block)
        return [key,type,opts,block]
      end
      def config.get
        return 'gotconfig'
      end
      def config.set(config)
        return config
      end
      app.instance_variable_set(:@config, config)
      app
    end

    describe '#config' do
      let(:myblock){ lambda {} }
      it 'passes the block to config (and sets the right defaults)' do
        ret = app.config(&myblock)
        expect(ret).to eq([nil,Attributor::Struct,{},myblock])
      end

      it 'passes the params and block to config' do
        ret = app.config(:key, Attributor::Hash, {option: :one}, &myblock)
        expect(ret).to eq([:key, Attributor::Hash, {option: :one}, myblock])
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
      bootloader = double('bootloader')
      allow(bootloader).to receive(:setup!).and_return(true)

      app = double('built Rack app')

      builder = double('Rack builder')
      allow(builder).to receive(:run)
      allow(builder).to receive(:to_app).and_return(app)

      subject.instance_variable_set(:@bootloader, bootloader)
      subject.instance_variable_set(:@builder, builder)
    end

    describe '#handler' do
      let(:new_handler_name) { 'awesomesauce' }
      let(:new_handler) { double('awesomesauce encoder', generate: '', parse: {}) }
      let(:bad_handler) { double('bad handler', wokka: true, meep: false) }

      context 'given a Class' do
        let(:new_handler_class) { double('encoder with dependencies', new: new_handler) }

        it 'instantiates and registers an instance' do
          expect(new_handler_class).to receive(:new)
          subject.handler new_handler_name, new_handler_class
        end
      end

      context 'given a Module' do
        it 'registers the module' do
          subject.handler new_handler_name, new_handler

          expect(subject.handlers[new_handler_name]).to eq(new_handler)
        end
      end

      it 'overrides default handlers' do
        subject.handler 'json', new_handler
        subject.setup
        expect(subject.handlers['json']).to eq(new_handler)
      end

      it 'ensures that handlers will work' do
        expect {
          subject.handler new_handler_name, bad_handler
        }.to raise_error(ArgumentError)
      end
    end
  end
end
