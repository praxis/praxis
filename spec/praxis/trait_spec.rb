require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Praxis::Trait do

  subject(:trait) do
    Praxis::Trait.new do
      description 'my awesome trait'

      routing do
        prefix '/:app_name'
      end

      response :something
      response :nothing

      # Double params to test "additive behavior"
      params do
        attribute :app_name, String
      end
      params do
        attribute :order, String,
          description: "Field to sort by."
      end

      headers do
        header "Authorization"
        key "Header2", String, required: true
      end

    end
  end

  context 'describe' do
    subject(:describe) { trait.describe }

    its([:description]) { should eq('my awesome trait') }

    its([:responses, :something]) { should eq Hash.new }
    its([:responses, :nothing]) { should eq Hash.new }

    its([:params, :app_name, :type, :name]) { should eq 'String' }
    its([:params, :order, :type, :name]) { should eq 'String' }
    its([:routing, :prefix]) { should eq '/:app_name'}

    its([:headers, "Header2"]) { should include({present: true, null: false}) }
    context 'using the special DSL syntax for headers' do
      subject(:dsl_header) { describe[:headers]["Authorization"] }
      its([:present]){ should be(true) }
      its([:null]){ should be(false) }
      its([:type]){ should eq( { :id=>"Attributor-String", :name=>"String", :family=>"string"} )}
    end

  end

  context 'apply!' do
    let(:target) { double("Target") }
    it 'does' do
      expect(target).to receive(:routing).once
      expect(target).to receive(:response).twice
      expect(target).to receive(:params).twice
      expect(target).to receive(:headers).once
      subject.apply!(target)
    end
  end
end
