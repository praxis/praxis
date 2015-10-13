require 'spec_helper'

describe Praxis::ApiGeneralInfo do

  subject(:info){ Praxis::ApiGeneralInfo.new }

  before do
    allow(Praxis::Application.instance).to receive(:versioning_scheme=).with([:header, :params])
  end


  let(:info_block) do
    Proc.new do
      name "Name"
      title "Title"
      description "Description"
      endpoint 'api.example.com'
      base_path "/base"

      consumes 'xml', 'x-www-form-urlencoded'
      produces 'json', 'x-www-form-urlencoded'

      base_params do
        attribute :name, String
      end
    end
  end

  context 'setting' do
    it 'accepts the appropriate DSLs' do
      expect{
        info.instance_exec &info_block
      }.to_not raise_error
    end
  end

  context 'getting values' do
    before do
      info.instance_exec &info_block
    end

    its(:name) { should eq 'Name' }
    its(:consumes) { should eq ['xml', 'x-www-form-urlencoded']}
    its(:produces) { should eq ['json', 'x-www-form-urlencoded']}
  end

  context '.describe' do
    before do
      info.instance_exec &info_block
    end

    subject(:output){ info.describe }
    its([:schema_version]) {should eq '1.0' }
    its([:name]) {should eq 'Name' }
    its([:title]) {should eq 'Title' }
    its([:description]) {should eq 'Description' }
    its([:base_path]) {should eq '/base' }
    its([:base_params]) { should have_key :name }
    its([:base_params, :name, :type, :name]) { should eq 'String' }
    its([:version_with]) { should eq([:header, :params]) }
    its([:endpoint]) { should eq 'api.example.com' }
    its([:consumes]) { should eq ['xml', 'x-www-form-urlencoded'] }
    its([:produces]) { should eq ['json', 'x-www-form-urlencoded'] }
  end

  context 'base_path with versioning' do
    let(:global_info){ Praxis::ApiGeneralInfo.new }
    subject(:info){ Praxis::ApiGeneralInfo.new(global_info, version: '1.0') }

    before do
      global_info

      expect(Praxis::Application.instance).to receive(:versioning_scheme=).with(:path)

      global_info.version_with :path
      global_info.base_path '/api/v:api_version'
    end    

    its(:base_path) { should eq '/api/v1.0'}
  end

end
