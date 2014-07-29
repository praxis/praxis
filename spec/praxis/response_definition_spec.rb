require "spec_helper"

describe Praxis::ResponseDefinition do
  subject(:response_definition) { Praxis::ResponseDefinition.new(name, &block) }
  let(:name) { 'response_name' }

  let(:block) do
    Proc.new do
      status 200
      description 'test description'
      headers({ "X-Header" => "value", "Content-Type" => "some_type" })
    end
  end

  its(:status) { should == 200 }
  its(:description) { should == 'test description' }

  let(:response_status) { 200 }
  let(:response_headers) { { "X-Header" => "value", "Content-Type" => "some_type"} }
  let(:response) { instance_double("Praxis::Response", status: response_status , headers: response_headers ) }


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

    it 'accepts a SimpleMediaTyoe' do
      simple = Praxis::SimpleMediaType.new('application/json')
      response_definition.media_type simple
      expect(response_definition.media_type).to be(simple)
    end

    it 'should return an error when media_type is not a String or a MediaType' do
      expect{ response_definition.media_type Object.new }.to raise_error(/Invalid media_type specification/)
    end

    it 'should return an error when media_type is a Symbol other than :controller_defined' do
      expect{ response_definition.media_type :symbol }.to raise_error(/Invalid media_type specification/)
    end
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
      expect { response_definition.location Object.new }.to raise_error(/Invalid location specification/)
    end
  end

  context '#headers' do
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
            }.to raise_error(/Invalid response code detected./)
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
              }.to raise_error(/LOCATION does not match regexp/)
            end
          end

          context 'for String' do
            let(:location) { "no_match" }
            it 'should raise error' do
              expect {
                response_definition.validate_location!(response)
              }.to raise_error(/LOCATION does not match string/)
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
               }.to raise_error(/headers missing/)
             end
           end
 
           context "when headers specs are name strings" do
             context "and is missing" do
               let (:headers) { [ "X-Just-Key" ] }
               it 'should raise error' do
                 expect {
                 response_definition.validate_headers!(response)
                 }.to raise_error(/headers missing/)
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
                 [ { "X-Header" => "notfoodbar" } ]
               }
               it 'should raise error' do
                 expect {
                   response_definition.validate_headers!(response)
                 }.to raise_error(/headers missing/)
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
                 }.to raise_error(/headers missing/)
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
              let(:response_headers) { {'Content-Type' => content_type } }
              it 'should raise error telling you so' do
                expect {
                  response_definition.validate_content_type!(response)
                }.to_not raise_error
              end
            end

            context 'when content type does not match' do
              let(:response_headers) { {'Content-Type' => "will_never_match" } }
              it 'should raise error telling you so' do
                expect {
                  response_definition.validate_content_type!(response)
                }.to raise_error(/Bad Content-Type/)
              end
            end

            context 'when content type is not set' do
              let(:response_headers) { {} }
              it 'should still raise an error' do
                expect {
                  response_definition.validate_content_type!(response)
                }.to raise_error(/Bad Content-Type/)
              end
            end
          end
      end

    end

  end
#  
#  context 'multipart responses' do
#        let(:part) { Praxis::MultipartPart.new('not so ok', {'Status' => 400, "Location" => "somewhere"}) }
#
#        context '#add_part' do
#
#          context 'without a name' do
#            before do
#              response.add_part(part)
#            end
#
#            its(:parts) { should have(1).item }
#
#            it 'sets the Content-Type header' do
#              expect(response.headers['Content-Type']).to match(/^multipart.*boundary=/i)
#            end            
#
#            it 'adds the part' do
#              expect(response.parts.values.first).to be(part)
#            end
#          end
#
#          context 'with a name' do
#            let(:part_name) { 'a-part' }
#            before do
#              response.add_part(part_name, part)
#            end
#
#            it 'adds the part' do
#              expect(response.parts[part_name]).to be(part)
#            end
#          end
#
#        end
#
#        context '#finish for a multipart response' do
#
#          before do
#            response.add_part(part)
#            response.body = 'a preamble'
#            response.status = 500
#          end
#
#          let!(:finished_response) { response.finish }
#
#          it 'returns status, headers, body' do
#            expect(finished_response).to eq([response.status, response.headers, response.body])
#          end
#
#          its(:status) { should eq(500) }
#
#          it 'sets a preamble in the body' do
#            expect(response.body[0]).to eq('a preamble')
#            expect(response.body[1]).to eq("\r\n")
#          end
#
#          it 'sets the headers' do
#            expect(response.headers['Content-Type']).to match(/multipart\/form-data/)
#            expect(response.headers['Location']).to eq('/api/resources/123')
#          end
#
#          it 'encodes the body properly' do
#            parser = Praxis::MultipartParser.new(response.headers, response.body)
#            preamble, parts = parser.parse
#
#            expect(preamble).to eq("a preamble")
#            expect(parts).to have(1).item
#
#            _part_name, part_response = parts.first
#            expect(part_response.headers['Status']).to eq(part.headers['Status'].to_s)
#            expect(part_response.headers['Location']).to eq(part.headers['Location'])
#            expect(part_response.body).to eq('not so ok')
#          end
#        end
#
#  end
#  
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
