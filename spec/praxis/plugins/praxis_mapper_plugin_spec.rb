require 'spec_helper'
require 'praxis/plugins/praxis_mapper_plugin.rb'

describe Praxis::Plugins::PraxisMapperPlugin do

  subject(:plugin) { Praxis::Plugins::PraxisMapperPlugin::Plugin.instance }
  let(:config) { plugin.config }

  context 'Plugin' do
    context 'configuration' do
      subject { config }
      its(:log_stats) { should eq 'detailed' }

      its(:repositories) { should have_key("default") }

      context 'default repository' do
        subject(:default) { config.repositories['default'] }
        its(['type']) { should eq 'sequel' }
        its(['connection_settings']) do
          should eq('adapter' => 'sqlite','database' => ':memory:')
        end
      end

    end
  end

  context 'functional test' do

    def app
      Praxis::Application.instance
    end

    let(:session) { double("session", valid?: true)}

    around(:each) do |example|
      orig_level = Praxis::Application.instance.logger.level
      Praxis::Application.instance.logger.level = 2
      example.run
      Praxis::Application.instance.logger.level = orig_level
    end

    it 'logs stats' do
      expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to receive(:log).
        with(kind_of(Praxis::Mapper::IdentityMap), 'detailed').
        and_call_original

      get '/clouds/1/instances/2?junk=foo&api_version=1.0', nil, 'global_session' => session

      expect(last_response.status).to eq(200)
    end

  end

  context 'Statistics' do
    context '.log' do
      let(:identity_map) { double('identity_map') }

      it 'when log_stats = detailed' do
        expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to receive(:detailed).with(identity_map)
        Praxis::Plugins::PraxisMapperPlugin::Statistics.log(identity_map, 'detailed')
      end

      it 'when log_stats = short' do
        expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to receive(:short).with(identity_map)
        Praxis::Plugins::PraxisMapperPlugin::Statistics.log(identity_map, 'short')
      end

      it 'when log_stats = skip' do
        expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to_not receive(:short)
        expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to_not receive(:detailed)
        Praxis::Plugins::PraxisMapperPlugin::Statistics.log(identity_map, 'skip')
      end

    end

    it 'has specs for testing the detailed log output'
    it 'has specs for testing the short log output'
  end

end
