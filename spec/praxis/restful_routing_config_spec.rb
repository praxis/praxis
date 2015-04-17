require 'spec_helper'

describe Praxis::Skeletor::RestfulRoutingConfig do

  let(:resource_definition) do
    Class.new do
      include Praxis::ResourceDefinition
      def self.name; 'MyResource'; end
    end
  end

  let(:action_name) { :index }
  let(:routing_block) { Proc.new{} }
  let(:default_route_prefix) { "/" + resource_definition.name.split("::").last.underscore }

  subject(:routing_config){ Praxis::Skeletor::RestfulRoutingConfig.new(action_name, resource_definition, &routing_block) }

  context "#initialize" do
    it "name" do
      expect(subject.name).to eq(:index)
    end

    it "resource_definition" do
      expect(subject.resource_definition).to eq(resource_definition)
    end

    it "routes" do
      expect(subject.routes.empty?).to eq(true)
    end

    it "prefix without path version" do
      expect(subject.prefix).to eq(default_route_prefix)
    end

    context 'prefix using path version' do
      let(:resource_definition) do
        Class.new do
          include Praxis::ResourceDefinition
          version "1.0", using: :path
          def self.name; 'MyVersionedResource'; end
        end
      end
      it "prefix" do
        expect(subject.prefix).to eq("/v1.0#{default_route_prefix}")
      end
    end
  end

  context "#add_route" do
    let(:route_verb){ 'GET' }
    let(:route_path){ '/*' }
    let(:route_opts){ {option: 1} }
    let(:route) { subject.routes.first }

    before(:each) do
      routing_config.add_route(route_verb, route_path, route_opts)
    end

    it "routes" do
      expect(subject.routes.length).to eq(1)
    end

    context "without a :mustermann_options key" do
      it "passes no options to Mustermann" do
        expect(route.path).to match("#{subject.prefix}/allowed")
        expect(route.path).to match("#{subject.prefix}/forbidden")
      end

      it "saves the verb and options into the route" do
        expect(route.verb).to eq(route_verb)
        expect(route.options).to eq(route_opts)
      end
    end

    context "with a :mustermann_options key" do
      let(:route_opts) { {option: 1, mustermann_options: {except: '*/forbidden'}} }

      it "passes the options to Mustermann" do
        expect(route.path).to match("#{subject.prefix}/allowed")
        expect(route.path).not_to match("#{subject.prefix}/forbidden")
      end

      it "does not save the Mustermann options in the route" do
        expect(route.options).to eq(route_opts.reject { |k, v| k == :mustermann_options })
      end
    end

    context "with a resource definition that does not have a route prefix" do
      it 'saves the path with the default path prefix' do
        expect(route.path.to_s).to eq(default_route_prefix + route_path)
      end
    end

    context "with a resource definition that has a route prefix" do
      let(:routing_block) { Proc.new{ prefix "/my_custom_route" } }
      subject(:routing_config){ Praxis::Skeletor::RestfulRoutingConfig.new(action_name, resource_definition, &routing_block) }
      it 'appends the prefix to the path' do
        expect(route.path.to_s).to eq("/my_custom_route" + route_path)
      end

    end
  end

  context 'route helpers' do
    let(:route_prefix) { nil }

    it 'call the add_route with the correct parameters' do
      helper_verbs = [:get, :put, :post, :delete, :head, :options, :patch, :any]
      helper_verbs.each do |verb|
        path = "/path_for_#{verb}"
        options = {option: verb}
        expect(subject).to receive(:add_route).with(verb.to_s.upcase,path,options)
        subject.__send__(verb, path, options)
      end
    end
  end

end
