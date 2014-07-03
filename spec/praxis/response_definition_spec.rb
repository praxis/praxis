require "spec_helper"

describe Praxis::ResponseDefinition do
  subject(:response_definition) { Praxis::ResponseDefinition.new(name, &block) }
  let(:name) { 'response_name' }

  class ExampleMediaType < Praxis::MediaType; end

  context 'with a correct and full definition' do
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
          response_def = Praxis::ResponseDefinition.new(name) do
            status 200
            media_type ExampleMediaType
          end
          expect(response_def.media_type).to be(ExampleMediaType)
        end

        it 'accepts a string and returns a SimpleMediaType' do
          response_def = Praxis::ResponseDefinition.new(name) do
            status 200
            media_type 'string'
          end
          expect(response_def.media_type).to be_kind_of(Praxis::SimpleMediaType)
        end

        it 'accepts a Symbol :controller_defined' do
          response_def = Praxis::ResponseDefinition.new(name) do
            status 200
            media_type :controller_defined
          end
          expect(response_def.media_type).to be(:controller_defined)
        end
      end

      context 'such as location' do
        it 'accepts a String' do
          expect do
            Praxis::ResponseDefinition.new( name ) do
              status 200
              location "string_location"
            end
          end.to_not raise_error
        end

        it 'accepts a Regex' do
          expect do
            Praxis::ResponseDefinition.new( name ) do
              status 200
              location /regex_location/
            end
          end.to_not raise_error
        end
      end

      context 'such as headers' do
        it 'accepts a Hash' do
          expect do
            Praxis::ResponseDefinition.new( name ) do
              status 200
              headers Hash["X-Header" => "value", "Content-Type" => "some_type"]
            end
          end.to_not raise_error
        end

        it 'accepts an Array' do
          expect do
            Praxis::ResponseDefinition.new( name ) do
              status 200
              headers ["X-Header: value", "Content-Type: some_type"]
            end
          end.to_not raise_error
        end

        it 'accepts a String' do
          expect do
            Praxis::ResponseDefinition.new( name ) do
              status 200
              headers "X-Header: value"
            end
          end.to_not raise_error
        end
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

    it 'should return an error when location is not a Regex or a String object' do
      expect{
        Praxis::ResponseDefinition.new( name ) do
          status 200
          location Object.new
        end
      }.to raise_error(/Invalid location specification/)
    end

    it 'should return an error when headers are not a Hash, Array or String object' do
      expect{
        Praxis::ResponseDefinition.new( name ) do
          status 200
          headers Object.new
        end
      }.to raise_error(/Invalid headers specification/)
    end

    it 'should return an error when media_type is not a String or a MediaType' do
      expect{
        Praxis::ResponseDefinition.new( name ) do
          status 200
          media_type Object.new
        end
      }.to raise_error(/Invalid media_type specification/)
    end

    it 'should return an error when media_type is a Symbol other than :controller_defined' do
      expect{
        Praxis::ResponseDefinition.new( name ) do
          status 200
          media_type :symbol
        end
      }.to raise_error(/Invalid media_type specification/)
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
      its(:status) { should be(202)}
      its(:headers) { should eq('Some-Header')}
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

  context 'getting data from describe' do
    it 'is a pending example'
  end
end
