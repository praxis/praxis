require 'spec_helper'

describe Praxis::ApiGeneralInfo do
  
  subject(:info){ Praxis::ApiGeneralInfo.new }
  
  let(:info_block) do
    Proc.new do
      name "Name"
      title "Title"
      description "Description"
      base_path "/base"
    end
  end
  
  context 'DSLs' do
    it 'accepts the appropriate DSLs' do
      expect{ 
        info.instance_exec &info_block
      }.to_not raise_error
    end
    
  end

  context '.describe' do
    subject(:output){ info.describe }
    it 'works' do
      info.instance_exec &info_block
      expect(output).to eq( 
        {:schema_version=>"1.0", :name=>"Name", :title=>"Title", 
          :description=>"Description", :base_path=>"/base"
        })
    end
    
  end
end