require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Praxis::Skeletor::RestfulRoutingConfig do

  class MyResource
    include Praxis::ResourceDefinition
  end

  let(:action_name) { :index }
  let(:resource_definition) { MyResource }
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

    it "prefix" do
      expect(subject.prefix).to eq(default_route_prefix)
    end
  end

  context "#add_route" do
    let(:route_verb){ 'GET' }
    let(:route_path){ '/path' }
    let(:route_opts){ {option: 1} }

    before(:each) do
      routing_config.add_route( route_verb, route_path, route_opts)
    end

    it "routes" do
      expect(subject.routes.length).to eq(1)
    end

    it "should save the verb and options into the route" do
      v,p,o = subject.routes.first
      expect(v).to eq(route_verb)
      expect(o).to eq(route_opts)
    end

    context "without a controller having a route prefix" do
      it 'should save the path with the default path prefix' do
        v,p,o = subject.routes.first
        expect(p).to eq(default_route_prefix + route_path)
      end
    end
    context "with a controller having a custom route prefix" do
      let(:routing_block) { Proc.new{ prefix "/my_custom_route" } }
      subject(:routing_config){ Praxis::Skeletor::RestfulRoutingConfig.new(action_name, resource_definition, &routing_block) }
      it 'should append the prefix to the path' do
        v,p,o = subject.routes.first
        expect(p).to eq("/my_custom_route" + route_path)
      end

    end
  end

  context 'route helpers' do
    let(:route_prefix) { nil }

    it 'call the add_route with the correct parameters' do
      helper_verbs = [:get, :put, :post, :delete, :head, :options, :patch ]
      helper_verbs.each do |verb|
        subject.send(verb, "/path_for_#{verb}", {option: verb} )
      end
      expect(subject.routes.count).to eq(helper_verbs.size)
      expect(subject.routes.include?(['GET', "#{default_route_prefix}/path_for_get" , {option: :get}])).to eq(true)
      expect(subject.routes.collect {|r| r.first.downcase.to_sym }).to match_array(helper_verbs)
    end
  end

  it '#describe' do
    expect(subject.describe).to eq(subject.routes)
  end
end
