require 'spec_helper'

describe Praxis::Application do
  describe 'configuration' do
    subject(:app) do
      app = Class.new(Praxis::Application).instance

      config = Object.new
      def config.define(&block)
        return block
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
      it 'passes the block to config' do
        myblock = lambda {}
        ret = app.config(&myblock)

        expect(ret).to be(myblock)
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
