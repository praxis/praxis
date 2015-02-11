require 'spec_helper'

describe Praxis::ApiDefinition do
  
  Praxis::ApiDefinition.define do |api|
    api.response_template :template1, &Proc.new {} 
    api.trait :trait1, &Proc.new {} 
  end
  
  subject(:api) {Praxis::ApiDefinition.instance}
  
  context 'singleton' do
    subject(:api){  Praxis::ApiDefinition.instance }  
    it 'should be a Singleton' do
      expect(Praxis::ApiDefinition.ancestors).to include( Singleton )
      expect(subject).to eq(Praxis::ApiDefinition.instance )
    end
    
    it 'has the :ok and :created response templates registered' do
      expect(api.responses.keys).to include(:ok)
      expect(api.responses.keys).to include(:created)
    end 
  end
  
  context '.response_template' do
    let(:response_template){ Proc.new {} }
    
    it 'has the defined template1 response_template' do
      expect(api.responses.keys).to include(:template1)
      expect(api.response(:template1)).to be_kind_of(Praxis::ResponseTemplate)
    end
    it 'also works outside a .define block' do
      api.response_template :foobar, &response_template
      expect(api.responses.keys).to include(:foobar)
      expect(api.response(:foobar)).to be_kind_of(Praxis::ResponseTemplate)
    end
  end
  
  context '.response' do
    it 'returns a registered response by name' do
      expect(api.response(:template1)).to be_kind_of(Praxis::ResponseTemplate)
    end
  end
  
  context '.trait' do
    let(:trait2){ Proc.new{} }
    it 'has the defined trait1 ' do
      expect(api.traits.keys).to include(:trait1)
      expect(api.traits[:trait1]).to be_kind_of(Proc)
    end
    
    it 'saves it verbatim' do
      api.trait :trait2, &trait2
      expect(api.traits[:trait2]).to be(trait2)
    end
    
    it 'complains trying to register traits with same name' do
      expect{ 
        api.trait :trait2, &trait2
      }.to raise_error(Praxis::Exceptions::InvalidTrait, /Overwriting a previous trait with the same name/)
    end
  end
  
  context '.info' do
    let(:info_block) do
      Proc.new do
        name "Name"
        title "Title"
      end
    end 

    context 'with a version' do
      it 'saves the data into the correct version hash' do
        expect(api.infos.keys).to_not include("9.0")
        api.info("9.0", &info_block)
        expect(api.infos.keys).to include("9.0")
      end
      it 'immediate invokes the block' do
        expect(api.infos["9.0"]).to receive(:instance_eval)      
        api.info("9.0", &info_block)
      end
    end    
    context 'without a version' do
      it 'saves it into nil if no version is passed' do
        expect(api.infos.keys).to_not include(nil)
        api.info do
          description "Global Description"
        end
        expect(api.infos.keys).to include(nil)
      end
    end
  end
  
  context '.describe' do
    subject(:output){ api.describe }

    its(:keys){ should include("9.0") }  

    context 'for v9.0 info' do
      subject(:v9_info){ output["9.0"][:info] }
      
      it 'has the info it was set in the call' do
        expect(v9_info).to include({schema_version: "1.0"})
        expect(v9_info).to include({name: "Name"})
        expect(v9_info).to include({title: "Title"})
      end
      it 'inherited the description from the nil(global) one' do
        expect(v9_info).to include({description: "Global Description"})
      end

    end

  end
end