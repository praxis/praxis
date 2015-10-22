require 'spec_helper'

describe Praxis::Plugins::PraxisMapperPlugin do

  subject(:plugin) { Praxis::Plugins::PraxisMapperPlugin::Plugin.instance }
  let(:config) { plugin.config }

  context 'Plugin' do
    context 'configuration' do
      subject { config }
      its(:log_stats) { should eq 'detailed' }
      its(:stats_log_level) { should eq :info }
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

  context 'Request' do

    it 'should have identity_map accessors' do
      expect(Praxis::Plugins::PraxisMapperPlugin::Request.instance_methods).to include(:identity_map,:identity_map=)
    end

    it 'should have silence_mapper_stats accessors' do
      expect(Praxis::Plugins::PraxisMapperPlugin::Request.instance_methods)
            .to include(:silence_mapper_stats,:silence_mapper_stats=)
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

    context 'with no identity_map set in the request' do
      it 'does not log stats' do
        expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to_not receive(:log)
        the_body = StringIO.new("{}") # This is a funny, GET request expecting a body
        get '/api/clouds/1/instances/2?api_version=1.0', nil, 'rack.input' => the_body,'CONTENT_TYPE' => "application/json", 'global_session' => session

        expect(last_response.status).to eq(200)
      end
    end
    context 'with an identity_map set in the request' do
      it 'logs stats' do
        expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to receive(:log).
          with(kind_of(Praxis::Request),kind_of(Praxis::Mapper::IdentityMap), 'detailed').
          and_call_original
        the_body = StringIO.new("{}") # This is a funny, GET request expecting a body
        get '/api/clouds/1/instances/2?create_identity_map=true&api_version=1.0', nil, 'rack.input' => the_body,'CONTENT_TYPE' => "application/json", 'global_session' => session

        expect(last_response.status).to eq(200)
      end
    end

  end

  context 'Statistics' do
    context '.log' do
      let(:queries){ { some: :queries } }
      let(:identity_map) { double('identity_map', queries: queries) }
      let(:log_stats){ 'detailed' }
      let(:request){ double('request', silence_mapper_stats: false ) }

      after do
        Praxis::Plugins::PraxisMapperPlugin::Statistics.log(request, identity_map, log_stats)
      end

      context 'when the request silences mapper stats' do
        let(:request){ double('request', silence_mapper_stats: true ) }
        it 'should not log anything' do
          expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to_not receive(:to_logger)
        end
      end

      context 'without the request silencing mapper stats' do
        context 'when log_stats = detailed' do
          it 'should call the detailed method' do
             expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to receive(:detailed).with(identity_map)
           end
        end

        context 'when log_stats = short' do
          let(:log_stats){ 'short' }
          it 'should call the short method' do
             expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to receive(:short).with(identity_map)
           end
        end

        context 'when log_stats = skip' do
          let(:log_stats){ 'skip' }

          it 'should not log anything' do
            expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to_not receive(:to_logger)
          end
        end

        context 'when there is no identity map' do
          let(:identity_map) { nil }
          it 'should not log anything' do
            expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to_not receive(:to_logger)
          end
        end

        context 'when no queries are logged in the identity map' do
          let(:queries){ {} }
          it 'should log a special message' do
            expect(Praxis::Plugins::PraxisMapperPlugin::Statistics).to receive(:to_logger)
                                                                   .with("No database interactions observed.")
          end
        end

      end
    end

    it 'has specs for testing the detailed log output'
    it 'has specs for testing the short log output'
  end

end
