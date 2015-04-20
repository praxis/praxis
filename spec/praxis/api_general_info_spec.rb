require 'spec_helper'

describe Praxis::ApiGeneralInfo do

  subject(:info){ Praxis::ApiGeneralInfo.new }

  let(:info_block) do
    Proc.new do
      name "Name"
      title "Title"
      description "Description"
      base_path "/base"
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

  end
end
