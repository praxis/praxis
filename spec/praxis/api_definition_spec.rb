# frozen_string_literal: true

require 'spec_helper'

describe Praxis::ApiDefinition do
  subject(:api) { Praxis::ApiDefinition.instance }

  # Without getting a fresh new ApiDefinition it is very difficult to test stuff using the Singleton
  # So for some tests we're gonna create a new instance and work with it to avoid the singleton issues
  let(:non_singleton_api) do
    api_def = Praxis::ApiDefinition.__send__(:new)
    api_def.instance_eval do |api|
      api.response_template :template1, &proc {}
      api.trait :trait1, &proc {}
      api.trait :secondtrait do
        description 'the second testing trait'
      end

      api.info '1.0' do
        base_path '/apps/:app_name'
        base_params do
          attribute :app_name, String
        end
      end
    end
    api_def
  end

  let(:info_block) do
    proc do
      name 'Name'
      title 'Title'
    end
  end

  context 'singleton' do
    it 'should be a Singleton' do
      expect(Praxis::ApiDefinition.ancestors).to include(Singleton)
      expect(subject).to eq(Praxis::ApiDefinition.instance)
    end

    it 'has the :ok and :created response templates registered' do
      expect(api.responses.keys).to include(:ok)
      expect(api.responses.keys).to include(:created)
    end
  end

  context '.response_template' do
    let(:response_template) { proc {} }
    let(:api) { non_singleton_api }

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
    let(:api) { non_singleton_api }

    it 'returns a registered response by name' do
      expect(api.response(:template1)).to be_kind_of(Praxis::ResponseTemplate)
    end
  end

  context '.trait' do
    let(:api) { non_singleton_api }

    let(:trait2) { proc {} }

    it 'has the defined trait1 ' do
      expect(api.traits.keys).to include(:trait1)
      expect(api.traits[:trait1]).to be_kind_of(Praxis::Trait)
    end

    it 'complains trying to register traits with same name' do
      api.trait :trait2, &trait2
      expect do
        api.trait :trait2, &trait2
      end.to raise_error(Praxis::Exceptions::InvalidTrait, /Overwriting a previous trait with the same name/)
    end
  end

  context '.info' do
    let(:api) { non_singleton_api }
    subject(:info) { api.info('1.0') }

    context '.base_path' do
      its(:base_path) { should eq '/apps/:app_name' }
    end

    context '.base_params' do
      subject(:base_params) { info.base_params }
      it { should be_kind_of(Attributor::Attribute) }
      its(:attributes) { should include :app_name }
    end

    context 'with a version' do
      it 'saves the data into the correct version hash' do
        expect(api.infos.keys).to_not include('9.0')
        api.info('9.0', &info_block)
        expect(api.infos.keys).to include('9.0')
      end
    end

    context 'without a version' do
      it 'saves it into global_info' do
        expect(api.infos.keys).to_not include(nil)
        api.info do
          description 'Global Description'
        end
        expect(api.infos.keys).to_not include(nil)
        expect(api.global_info.description).to eq 'Global Description'
      end
    end
  end

  context '.describe' do
    subject(:output) { api.describe }

    context 'using the spec_app definitions' do
      subject(:version_output) { output['1.0'][:info] }

      context 'for the global_info data' do
        subject(:info) { output[:global][:info] }
        it { should include(:name, :title, :description) }
        its([:name]) { should eq 'Spec App' }
        its([:title]) { should eq 'A simple App to do some simple integration testing' }
        its([:description]) { should eq 'This example API should really be replaced by a set of more full-fledged example apps in the future' }
      end

      it 'outputs data for 1.0 info' do
        expect(output.keys).to include('1.0')
        expect(output['1.0']).to include(:info)
      end

      it 'describes 1.0 Api info properly' do
        info = output['1.0'][:info]
        expect(info).to include(:schema_version, :name, :title, :description, :base_path)
        expect(info[:schema_version]).to eq('1.0')
        expect(info[:name]).to eq('Spec App')
        expect(info[:title]).to eq('A simple App to do some simple integration testing')
        expect(info[:description]).to eq('A simple 1.0 App')
        expect(info[:base_path]).to eq('/api')
      end
    end

    context 'using a non-singleton object' do
      let(:api) { non_singleton_api }

      before do
        api.info('9.0', &info_block)
        api.info do
          description 'Global Description'
        end
      end
      its(:keys) { should include('9.0') }
      its(:keys) { should include :traits }
      its(%i[traits secondtrait]) { should eq api.traits[:secondtrait].describe }

      context 'for v9.0 info' do
        subject(:v9_info) { output['9.0'][:info] }

        it 'has the info it was set in the call' do
          expect(v9_info).to include({ schema_version: '1.0' })
          expect(v9_info).to include({ name: 'Name' })
          expect(v9_info).to include({ title: 'Title' })
        end
        it 'inherited the description from the nil(global) one' do
          expect(v9_info).to include({ description: 'Global Description' })
        end
      end
    end
  end
end
