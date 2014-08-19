require 'spec_helper'

describe Praxis::Application do
  describe 'configuration' do
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
end
