require 'spec_helper'

describe Praxis::RoutingConfig do

  let(:resource_definition) do
    Class.new do
      include Praxis::ResourceDefinition
      def self.name; 'MyResource'; end
    end
  end

  let(:routing_block) { Proc.new{} }
  let(:default_route_prefix) { "/" + resource_definition.name.split("::").last.underscore }

  subject(:routing_config){ Praxis::RoutingConfig.new(&routing_block) }

  its(:version) { should eq('n/a') }
  its(:prefix ) { should eq('') }

  context '#prefix' do
    it 'sets the prefix' do
      routing_config.prefix '/'
      expect(routing_config.prefix).to eq('/')
    end

    it 'is additive' do
      routing_config.prefix '/people/:id'
      routing_config.prefix '/address'
      expect(routing_config.prefix).to eq('/people/:id/address')
    end

    it 'strips duplicated /s' do
      routing_config.prefix '/'
      routing_config.prefix '/people'
      expect(routing_config.prefix).to eq('/people')
    end

  end

  context '#add_route' do
    let(:path) { '/people' }
    let(:options) { {} }
    let(:route) { routing_config.add_route 'GET', path, **options}

    it 'returns a corresponding Praxis::Route' do
      expect(route).to be_kind_of(Praxis::Route)
    end

    it 'appends the Route to the set of routes' do
      expect(routing_config.routes).to include(route)
    end

    context 'passing  options' do
      let(:options){ {name: 'alternative', except: '/special' } }

      it 'uses :name to name the route' do
        expect(route.name).to eq('alternative')
      end

      it 'does NOT pass the name option down to mustermann' do
        expect(Mustermann).to receive(:new).with(path, hash_excluding({name: 'alternative'}))
        expect(route.name).to eq('alternative')
      end

      it 'passes them through the underlying mustermann object (telling it to ignore unknown ones)' do
        expect(Mustermann).to receive(:new).with(path, hash_including(ignore_unknown_options: true, except: '/special'))
        expect(route.options).to eq( { except: '/special' })
      end
    end

    context 'with prefix defined' do
      before do
        routing_config.prefix '/parents/:parent_id'
      end

      it 'includes the prefix in the route path' do
        expect(route.path.to_s).to eq '/parents/:parent_id/people'
      end

      context 'for paths beginning with //' do
        let(:path) { '//people' }
        it 'does not include the prefix in the route path' do
          expect(route.path.to_s).to eq '/people'
        end
      end
    end
  end

end
