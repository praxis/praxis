require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Praxis::ResourceDefinition do
  let(:routing_href) { '/clouds/1/instances' }
  let(:media_type) { 'my_media_type' }
  let(:version) { '1.0' }
  let(:response_group) { 'my_response_group' }
  let(:response) { 'my_response' }
  let(:description) { 'my_description' }
  let(:header_opts) { {opt1: "option1", opt2: "option2"} }
  let(:my_proc) { Proc.new{|s| puts s } }

  class MyMediaType < Praxis::MediaType
    identifier 'application/json'

    attributes do
      attribute :id, Integer
    end
  end

  class MyResource
    include Praxis::ResourceDefinition

    media_type MyMediaType
    #use :authenticated

    description "default description"

    routing do
      prefix "/my_resources"
    end

    params do
      attribute :id, Integer, required: true
    end

    payload do

    end

    headers do

    end

    action :index do
      description 'index description'
      routing do
        get ''
      end
    end

    action :show do
      description 'show description'
      routing do
        get '/:id'
      end
      params do
        attribute :id, Integer, required: true, min: 1
      end
    end
  end

  subject do
    MyResource
  end

  it "#routing" do
    expect(subject.routing_config.class).to eq(Proc)
  end

  it "#media_type" do
    expect(subject.media_type).to eq(MyMediaType)
    expect(subject.media_type(media_type).class).to eq(Praxis::SimpleMediaType)
    expect(subject.media_type(media_type).identifier).to eq(media_type)
  end

  it "#version" do
    expect(subject.version).to eq('n/a')
    expect(subject.version(version)).to eq(version)
  end

  it "#action" do
    expect(subject.actions[:index].class).to eq(Praxis::ActionDefinition)
    expect(subject.actions[:index].description).to eq("index description")
    expect(subject.actions[:show].class).to eq(Praxis::ActionDefinition)
    expect(subject.actions[:show].description).to eq("show description")
    expect(subject.actions[:nonexistent_action]).to be_nil
  end

  it "#params" do
    expect(subject.params[0]).to eq(Attributor::Struct)
    expect(subject.params[1].class).to eq(Hash)
    expect(subject.params[2].class).to eq(Proc)
  end

  it "#payload" do
    expect(subject.payload[0]).to eq(Attributor::Struct)
    expect(subject.payload[1].class).to eq(Hash)
    expect(subject.payload[2].class).to eq(Proc)
  end

  it "#headers" do
    expect(subject.headers[0].class).to eq(Hash)
    expect(subject.headers[1].class).to eq(Proc)
  end

  it "#description" do
    expect(subject.description).to eq("default description")
    expect(subject.description(description)).to eq(description)
  end

  it "#responses" do
    expect(subject.responses).to eq(Set.new)
    expect(subject.responses(response)).to eq(Set[response])
  end

  it "#response_groups" do
    expect(subject.response_groups).to eq(Set[:default])
    expect(subject.response_groups(response_group)).to eq(Set[:default, response_group])
  end

  it "#describe" do
    hash = subject.describe

    expect(hash[:description]).to eq("default description")
    #expect(hash[:media_type]).to eq(MyMediaType.name)
    actions = hash[:actions]
    expect(actions.length).to eq(2)
  end

  it "#use" do
    pending("TBD")
    this_should_not_get_executed
    #expect(subject.use(:non_existent_trait)).to raise_error
  end
end
