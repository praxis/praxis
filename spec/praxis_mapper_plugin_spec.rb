require 'spec_helper'

describe PraxisMapperPlugin do

  subject(:plugin) { PraxisMapperPlugin::Plugin.instance }
  let(:config) { plugin.config }
  
  context 'Plugin' do
    context 'configuration' do
      subject { config }
      its(:log_stats) { should eq 'skip' }

      its(:repositories) { should have_key("default") }

      context 'default repository' do
        subject(:default) { config.repositories['default'] }
        its(['type']) { should eq 'sequel' }
        its(['connection_settings']) { should eq('adapter' => 'sqlite','database' => ':memory:')}
      end

    end
  end

  context 'functional test' do

    def app
      Praxis::Application.instance
    end

    let(:session) { double("session", valid?: true)}

    it 'logs stats' do
      expect(PraxisMapperPlugin::Statistics).to receive(:log).with(kind_of(Praxis::Mapper::IdentityMap)).and_call_original

      get '/clouds/1/instances/2?junk=foo&api_version=1.0', nil, 'global_session' => session
      expect(last_response.status).to eq(200)
    end

  end

  context 'Statistics' do
    context '.log' do
      let(:identity_map) { double('identity_map') }

      after do
        PraxisMapperPlugin::Statistics.log(identity_map)
      end

      it 'when log_stats = detailed' do
        expect(config).to receive(:log_stats).and_return 'detailed'
        expect(PraxisMapperPlugin::Statistics).to receive(:detailed).with(identity_map)
      end

      it 'when log_stats = detailed' do
        expect(config).to receive(:log_stats).and_return 'short'
        expect(PraxisMapperPlugin::Statistics).to receive(:short).with(identity_map)
      end

      it 'when log_stats = skip' do
        expect(config).to receive(:log_stats).and_return 'skip'
        expect(PraxisMapperPlugin::Statistics).to_not receive(:short)
        expect(PraxisMapperPlugin::Statistics).to_not receive(:detailed)
      end

    end

    it 'has specs for testing the detailed log output'
    it 'has specs for testing the short log output'
  end

end
