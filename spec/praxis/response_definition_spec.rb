require "spec_helper"

describe Praxis::ResponseDefinition do
  subject(:response_definition) { Praxis::ResponseDefinition.new(name, &block) }
  let(:name) { 'response_name' }

  class ExampleMediaType < Praxis::MediaType; end

  let(:block) do
    Proc.new do
      status 200
      description 'test description'
      headers Hash.new("X-Header" => "value", "Content-Type" => "some_type")
    end
  end

  its(:status) { should == 200 }
  its(:description) { should == 'test description' }

  context 'for fields that can take multiple types' do
    context 'such as media_type' do
      it 'accepts a MediaType object and returns the media_type that was set' do
        response_definition.media_type ExampleMediaType
        expect(response_definition.media_type).to be(ExampleMediaType)
      end

      it 'accepts a string and returns a SimpleMediaType' do
        response_definition.media_type 'string'
        expect(response_definition.media_type).to be_kind_of(Praxis::SimpleMediaType)
      end

      it 'accepts a Symbol :controller_defined' do
        response_definition.media_type :controller_defined
        expect(response_definition.media_type).to be(:controller_defined)
      end

      it 'should return an error when media_type is not a String or a MediaType' do
        expect{ response_definition.media_type Object.new }.to raise_error(/Invalid media_type specification/)
      end

      it 'should return an error when media_type is a Symbol other than :controller_defined' do
        expect{ response_definition.media_type :symbol }.to raise_error(/Invalid media_type specification/)
      end
    end

    context 'such as location' do
      it 'accepts a String' do
        response_definition.location "string_location"
        expect(response_definition.location).to eq("string_location")
      end

      it 'accepts a Regex' do
        response_definition.location /regex_location/
        expect(response_definition.location).to eq(/regex_location/)
      end

      it 'should return an error when location is not a Regex or a String object' do
        expect { response_definition.location Object.new }.to raise_error(/Invalid location specification/)
      end
    end

    context 'such as headers' do
      it 'accepts a Hash' do
        response_definition.headers Hash["X-Header" => "value", "Content-Type" => "some_type"]
        expect(response_definition.headers).to be_a(Hash)
      end

      it 'accepts an Array' do
        response_definition.headers ["X-Header: value", "Content-Type: some_type"]
        expect(response_definition.headers).to eq(["X-Header: value", "Content-Type: some_type"])
      end

      it 'accepts a String' do
        response_definition.headers "X-Header: value"
        expect(response_definition.headers).to eq("X-Header: value")
      end

      it 'should return an error when headers are not a Hash, Array or String object' do
        expect{ response_definition.headers Object.new }. to raise_error(/Invalid headers specification/)
      end
    end
  end

  context 'with multipart' do
    subject(:multipart) { response.multipart }

    context 'using default envelope status' do
      let(:response) do
        Praxis::ResponseDefinition.new(name) do
          status 500
          multipart :always
        end
      end
      it { should_not be_nil }
      its(:name) { should be(:always) }
      its(:status) { should be(200) }
    end

    context 'defining the envelope' do
      let(:response) do
        Praxis::ResponseDefinition.new(name) do
          status 500
          multipart :optional do
            status 202
            headers 'Some-Header'
          end
        end
      end
      its(:name) { should be(:optional) }
      its(:status) { should be(202) }
      its(:headers) { should eq('Some-Header') }
    end

    context 'an invalid multipart mode' do
      it 'raises an error' do
        expect {
          Praxis::ResponseDefinition.new(name) do
            status 200
            multipart :never
          end
        }.to raise_error(/Invalid multipart mode/)
      end
    end
  end

  context 'with invalid definitions' do
    it 'raises an error if status code is not part of the definition' do
      expect do
        Praxis::ResponseDefinition.new('response name') do
          description "testing"
        end
      end.to raise_error(/Status code is required/)
    end
  end

  context 'getting data from describe' do
    it 'is a pending example'
  end
end
