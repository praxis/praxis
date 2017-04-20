require "spec_helper"

describe Praxis::ResponseDefinition do
  subject(:response_definition) { Praxis::ResponseDefinition.new(name, **spec_options, &block) }
  let(:name) { 'response_name' }
  let(:spec_options) { {} }

  let(:block) do
    Proc.new do
      status 200
      description 'test description'
      headers({ "X-Header" => "value", "Content-Type" => "application/some-type" })
    end
  end

  its(:status) { should == 200 }
  its(:description) { should == 'test description' }
  its(:parts) { should be(nil) }
  let(:response_status) { 200 }
  let(:response_content_type) { "application/some-type" }
  let(:response_headers) { { "X-Header" => "value", "Content-Type" => response_content_type} }

  let(:response) { instance_double("Praxis::Response", status: response_status , headers: response_headers, content_type: response_content_type ) }


  context '#media_type' do
    it 'accepts a MediaType object and returns the media_type that was set' do
      example_media_type = Class.new(Praxis::MediaType)
      response_definition.media_type example_media_type
      expect(response_definition.media_type).to be(example_media_type)
    end

    it 'accepts a string and returns a SimpleMediaType' do
      response_definition.media_type 'string'
      expect(response_definition.media_type).to be_kind_of(Praxis::SimpleMediaType)
    end

    it 'accepts a SimpleMediaType' do
      simple = Praxis::SimpleMediaType.new('application/json')
      response_definition.media_type simple
      expect(response_definition.media_type).to be(simple)
    end

    it 'should return an error when media_type is not a String or a MediaType' do
      expect{ response_definition.media_type Object.new }.to raise_error(Praxis::Exceptions::InvalidConfiguration)
    end

    it 'should return an error when media_type is a Symbol other than :controller_defined' do
      expect{ response_definition.media_type :symbol }.to raise_error(Praxis::Exceptions::InvalidConfiguration)
    end
  end

#  context 'providing an explicit block' do
#    let(:response_example_block){ -> { {id: 123} } }
#    let(:spec_options){ {example: response_example_block } }
#
#    it 'should yield that result' do
#
#      response_definition.media_type example_mt
#
#      binding.pry
#      response_definition.example
##      expect(response_definition.describe).to have_key(:example)
#      expect(response_definition.describe[:example]).to eq(response_example_block.call)
#    end
#  end

  context '#example' do
    let(:media_type) { nil }

    before do
      response_definition.media_type media_type
    end

    context 'with media_type unset' do
      its(:example) { should be nil }
      it 'is not in the describe output' do
        expect(response_definition.describe).to_not have_key(:example)
      end
    end

    context 'with media_type set to a string' do
      let(:media_type) { 'application/json' }
      its(:example) { should be nil }
      it 'is not in the describe output' do
        expect(response_definition.describe).to_not have_key(:example)
      end
    end

    # TODO: Complete/correct the "example" generation when it is done in the ResponseDefinition class
    #context 'with media_type set to a MediaType' do
    #  let(:media_type) { Person }
    #
    #  let(:expected_context) { "Person-#{name}" }
    #  let!(:example) { Person.example(expected_context) }
    #
    #  before do
    #    expect(Person).to receive(:example).with(expected_context).and_call_original
    #  end
    #
    #  its(:example) { should be_kind_of(Person) }
    #  it 'is rendered in the describe output' do
    #    expect(response_definition.describe[:example]).to eq(example.render)
    #  end
    #end
  end

  context '#location' do
    it 'accepts a String' do
      response_definition.location "string_location"
      expect(response_definition.location).to eq("string_location")
    end

    it 'accepts a Regex' do
      response_definition.location /regex_location/
      expect(response_definition.location).to eq(/regex_location/)
    end

    it 'should return an error when location is not a Regex or a String object' do
      expect { response_definition.location Object.new }.to raise_error(Praxis::Exceptions::InvalidConfiguration)
    end
  end

  context '#headers' do
    it 'accepts a Hash' do
      response_definition.headers Hash["X-Header" => "value", "Content-Type" => "application/some-type"]
      expect(response_definition.headers).to be_a(Hash)
    end

    it 'accepts an Array' do
      response_definition.headers ["X-Header: value", "Content-Type: application/some-type"]
      expect(response_definition.headers).to be_a(Hash)
      expect(response_definition.headers.keys).to include("X-Header: value", "Content-Type: application/some-type")
    end

    it 'accepts a String' do
      response_definition.headers "X-Header: value"
      expect(response_definition.headers).to be_a(Hash)
      expect(response_definition.headers.keys).to include("X-Header: value")
    end

    it 'should return an error when headers are not a Hash, Array or String object' do
      expect{ response_definition.headers Object.new }. to raise_error(Praxis::Exceptions::InvalidConfiguration)
    end
  end

  context '#parts' do
    context 'with a :like argument (and no block)' do
      before do
        response_definition.parts like: :ok, media_type: 'application/special'
      end

      subject(:parts) { response_definition.parts }

      it{ should be_kind_of(Praxis::ResponseDefinition) }
      its('media_type.identifier'){ should == 'application/special' }
      its(:name){ should be(:ok) }
      its(:status){ should be( 200 ) }

    end
    context 'without a :like argument, and without a block' do
      it 'complains' do
        expect{
          response_definition.parts media_type: 'application/special'
        }.to raise_error(ArgumentError, /needs a :like argument or a block/)
      end
    end
    context 'with a :like argument, and a block' do
      it 'complains' do
        expect{
          response_definition.parts like: :something, media_type: 'application/special' do
          end
        }.to raise_error(ArgumentError, /does not allow :like and a block simultaneously/)
      end
    end

    context 'with a proc' do
      let(:the_proc) do
        Proc.new do
          status 201
          media_type 'from_proc'
        end
      end

      before do
        response_definition.parts the_proc
      end

      subject(:parts) { response_definition.parts }

      it{ should be_kind_of(Praxis::ResponseDefinition) }
      its('media_type.identifier'){ should == 'from_proc' }
      its(:status){ should be( 201 ) }

    end

    context 'with a block' do
      before do
        response_definition.parts do
          status 201
          media_type 'from_proc'
        end
      end

      subject(:parts) { response_definition.parts }

      it{ should be_kind_of(Praxis::ResponseDefinition) }
      its('media_type.identifier'){ should == 'from_proc' }
      its(:status){ should be( 201 ) }

    end
  end
  #  context '#multipart' do
  #    subject(:multipart) { response.multipart }
  #
  #    context 'using default envelope status' do
  #      let(:response) do
  #        Praxis::ResponseDefinition.new(name) do
  #          status 500
  #          multipart :always
  #        end
  #      end
  #      it { should_not be_nil }
  #      its(:name) { should be(:always) }
  #      its(:status) { should be(200) }
  #    end
  #
  #    context 'defining the envelope' do
  #      let(:response) do
  #        Praxis::ResponseDefinition.new(name) do
  #          status 500
  #          multipart :optional do
  #            status 202
  #            headers 'Some-Header'
  #          end
  #        end
  #      end
  #      its(:name) { should be(:optional) }
  #      its(:status) { should be(202) }
  #      its(:headers) { should eq('Some-Header') }
  #    end
  #
  #    context 'an invalid multipart mode' do
  #      it 'raises an error' do
  #        expect {
  #          Praxis::ResponseDefinition.new(name) do
  #            status 200
  #            multipart :never
  #          end
  #        }.to raise_error(/Invalid multipart mode/)
  #      end
  #    end
  #  end
  #

  context '#validate' do
    context 'functional test' do

      it "calls all the validation sub-functions" do
        expect(response_definition).to receive(:validate_status!).once
        expect(response_definition).to receive(:validate_location!).once
        expect(response_definition).to receive(:validate_headers!).once
        expect(response_definition).to receive(:validate_content_type!).once
        response_definition.validate(response)
      end
    end

    describe 'custom validate_xxx! methods' do

      describe "#validate_status!" do
        context 'that is completely valid' do
          it 'should succeed' do
            expect {
              response_definition.validate_status!(response)
            }.to_not raise_error
          end
        end


        context 'with internal error' do
          let(:response_status) { 500 }
          it 'should raise an error that later gets swallowed' do
            expect {
              response_definition.validate_status!(response)
            }.to raise_error(Praxis::Exceptions::Validation)
          end
        end

      end

      describe "#validate_location!" do
        let(:block) { proc { status 200 } }

        context 'checking location mismatches' do
          before { response_definition.location(location) }

          context 'for Regexp' do
            let(:location) { /no_match/ }

            it 'should raise an error' do
              expect {
                response_definition.validate_location!(response)
              }.to raise_error(Praxis::Exceptions::Validation)
            end
          end

          context 'for String' do
            let(:location) { "no_match" }
            it 'should raise error' do
              expect {
                response_definition.validate_location!(response)
              }.to raise_error(Praxis::Exceptions::Validation)
            end
          end

        end
      end

      describe "#validate_headers!" do
        before { response_definition.headers(headers) }
        context 'checking headers are set' do
          context 'when there are missing headers' do
            let (:headers) { { 'X-some' => 'test' } }
            it 'should raise error' do
              expect {
                response_definition.validate_headers!(response)
              }.to raise_error(Praxis::Exceptions::Validation)
            end
          end

          context "when headers specs are name strings" do
            context "and is missing" do
              let (:headers) { [ "X-Just-Key" ] }
              it 'should raise error' do
                expect {
                  response_definition.validate_headers!(response)
                }.to raise_error(Praxis::Exceptions::Validation)
              end
            end

            context "and is not missing" do
              let (:headers) { [ "X-Header" ] }
              it 'should not raise error' do
                expect {
                  response_definition.validate_headers!(response)
                }.not_to raise_error
              end
            end
          end

          context "when header specs are hashes" do
            context "and is missing" do
              let (:headers) {
                [ { "X-Just-Key" => "notfoodbar" } ]
              }
              it 'should raise error' do
                expect {
                  response_definition.validate_headers!(response)
                }.to raise_error(Praxis::Exceptions::Validation)
              end
            end

            context "and is not missing" do
              let (:headers) {
                [ { "X-Header" => "value" } ]
              }
              it 'should not raise error' do
                expect {
                  response_definition.validate_headers!(response)
                }.not_to raise_error
              end
            end
          end

          context "when header specs are of mixed type " do
            context "and is missing" do
              let (:headers) {
                [ { "X-Header" => "value" }, "not-gonna-find-me" ]
              }
              it 'should raise error' do
                expect {
                  response_definition.validate_headers!(response)
                }.to raise_error(Praxis::Exceptions::Validation)
              end
            end

            context "and is not missing" do
              let (:headers) {
                [ { "X-Header" => "value" }, "Content-Type" ]
              }
              it 'should not raise error' do
                expect {
                  response_definition.validate_headers!(response)
                }.not_to raise_error
              end
            end
          end
        end
      end

      describe "#validate_content_type!" do

        let(:response_headers) { {'Content-Type' => content_type } }
        let(:content_type) { 'application/none' }

        let(:media_type) do
          Class.new(Praxis::MediaType) do
            identifier 'application/none'
          end
        end

        context 'for definition without media_type defined' do
          it 'should not check that it matches the content type' do
            expect {
              response_definition.validate_content_type!(response)
            }.to_not raise_error
          end
        end

        context 'for definition that includes media_type defined' do
          before { response_definition.media_type(media_type) }

          context 'when content type matches the mediatype of the spec' do
            let(:response_content_type) { content_type }

            it 'validates successfully' do
              expect {
                response_definition.validate_content_type!(response)
              }.to_not raise_error
            end
          end

          context 'when content type includes a parameter' do
            let(:response_content_type) { "#{content_type}; collection=true" }
            it 'validates successfully' do
              expect {
                response_definition.validate_content_type!(response)
              }.to_not raise_error
            end
          end

          context 'when content type does not match' do
            let(:response_content_type) { "application/will_never_match" }

            it 'should raise error telling you so' do
              expect {
                response_definition.validate_content_type!(response)
              }.to raise_error(Praxis::Exceptions::Validation)
            end
          end

          context 'when content type is not set' do
            let(:response_headers) { {} }
            it 'should still raise an error' do
              expect {
                response_definition.validate_content_type!(response)
              }.to raise_error(Praxis::Exceptions::Validation)
            end
          end
        end
      end

      describe '#validate_parts!' do
        context 'with legacy multipart response' do
          subject(:response) { Praxis::Responses::Ok.new(status: response_status, headers: response_headers) }

          let(:part) { Praxis::MultipartPart.new('done', {'Status' => 200, 'Content-Type' => 'application/special'},{}) }

          before do
            response_definition.parts like: :ok, media_type: 'application/special'
            response.add_part(part)
          end

          it 'validates each part' do
            response_definition.parts
            expect {
              response_definition.validate_parts!(response)
            }.to_not raise_error
          end

          context 'with invalid part' do
            let(:part) { Praxis::MultipartPart.new('done', {'Status' => 200, "Location" => "somewhere"},{}) }

            it 'validates' do
              expect {
                response_definition.validate_parts!(response)
              }.to raise_error(Praxis::Exceptions::Validation)
            end

          end
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
      end.to raise_error(Praxis::Exceptions::InvalidConfiguration)
    end
  end

  context '.describe' do
    let(:description) { "A description" }
    let(:location) { %r{/my/url/} }
    let(:headers) { {'Header1' => 'Value1'} }
    let(:parts) { nil }

    let(:response) do
      Praxis::ResponseDefinition.new(:custom) do
        status 300
      end
    end
    subject(:output) { response.describe }

    before do
      response.description(description) if description
      response.location(location) if location
      response.parts(parts) if parts
      response.headers(headers) if headers
    end

    context 'for a definition with a media type' do
      let(:media_type) { Instance }
      subject(:payload) { output[:payload] }

      before do
        response.media_type Instance
      end

      its([:name]) { should eq 'Instance' }
      context 'examples' do
        subject(:examples) { payload[:examples] }
        its(['json', :content_type]) { should eq('application/vnd.acme.instance+json') }
        its(['xml', :content_type]) { should eq('application/vnd.acme.instance+xml') }

        it 'properly encodes the example bodies' do
          json = Praxis::Application.instance.handlers['json'].parse(examples['json'][:body])
          xml = Praxis::Application.instance.handlers['xml'].parse(examples['xml'][:body])
          expect(json).to eq xml
        end

      end

      context 'which does not have a identifier' do
        subject(:examples) { payload[:examples] }
        before do
          allow(response.media_type).to receive(:identifier).and_return(nil)
        end

        it 'still renders examples but as pure handler types for contents' do
          expect(subject['json'][:content_type]).to eq('application/json')
          expect(subject['xml'][:content_type]).to eq('application/xml')
        end
      end


    end


    context 'for a definition without parts' do
      it{ should be_kind_of(::Hash) }
      its([:description]){ should be(description) }
      its([:location]){ should == {value: location.inspect ,type: :regexp} }

      it 'should have a header defined with value and type keys' do
        expect( output[:headers] ).to have(1).keys
        expect( output[:headers]['Header1'] ).to eq({value: 'Value1' ,type: :string })
      end
    end

    context 'for a definition with (homogeneous) parts' do
      subject(:described_parts){ output[:parts_like] }
      context 'using :like' do
        let(:parts) { {like: :ok, media_type: 'foobar'} }

        it 'should contain a parts_like key with a hash' do
          expect( output ).to have_key(:parts_like)
        end

        it{ should be_kind_of(::Hash) }
        its([:payload]){ should ==  {id: 'Praxis-SimpleMediaType', name: 'Praxis::SimpleMediaType', family: 'string', identifier: 'foobar' } }
        its([:status]){ should == 200 }
      end
      context 'using a full response definition block' do
        let(:parts) do
          Proc.new do
            status 234
            media_type 'custom_media'
          end
        end

        it 'should contain a parts_like key with a hash' do
          expect( output ).to have_key(:parts_like)
        end

        it{ should be_kind_of(::Hash) }
        its([:payload]) { should == {id: 'Praxis-SimpleMediaType', name: 'Praxis::SimpleMediaType', family: 'string', identifier: 'custom_media'} }
        its([:status]) { should == 234 }
      end
    end
  end
end
