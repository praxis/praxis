require_relative "../spec_helper"


describe Praxis::Response do
  let(:spec_status)     { 200 }
  let(:spec_location)   { /resources/ }
  let(:spec_headers)    { { 'X-Header' => 'Foobar' } }
  let(:spec_mime_type)  { "application/vnd.resource" }

  let(:application_vnd_resource_media_type) do
    Class.new(Praxis::MediaType) do
      identifier 'application/vnd.resource'
    end
  end

  let(:application_none_media_type) do
    Class.new(Praxis::MediaType) do
      identifier 'application/none'
    end
  end

  let(:spec_media_type) { application_vnd_resource_media_type }

  let(:response_spec) do
    instance_double(
      Praxis::ResponseDefinition,
      :status     => spec_status,
      :location   => spec_location,
      :headers    => spec_headers,
      :media_type => spec_media_type,
      :multipart  => nil,
      :name       => :spec
    )
  end

  let(:action) do
    instance_double(
      Praxis::ActionDefinition,
      :resource_definition => config_class
     )
  end

  let(:response_status)  { 200 }
  let(:response_headers) {
    { 'Content-Type' => 'application/vnd.resource+json;type=collection',
      'X-Header'     => 'Foobar',
      'Location'     => '/api/resources/123' }
  }

  let(:config_media_type) { nil }
  let(:config_class) do
    instance_double(
      Praxis::ResponseDefinition,
      :media_type => config_media_type
    )
  end


  before :each do
    allow(subject.class).to receive(:response_name).and_return(:spec)
    allow(subject).to       receive(:headers).and_return(response_headers)
    allow(subject).to       receive(:status).and_return(response_status)
  end


  describe '#validate' do
    context 'response spec is not defined' do
      before :each do
        allow(subject.class).to receive(:response_name).and_return(:nonexisting_spec)
      end

      it 'should raise an error' do
        expect {
          subject.validate(action)
        }.to raise_error(ArgumentError, /no response defined with name :nonexisting_spec/)
      end
    end

    context 'functional test' do
      before :each do
        @action = 'dummy-action'
        expect(subject).to receive(:validate_status!).once
        expect(subject).to receive(:validate_location!).once
        expect(subject).to receive(:validate_headers!).once
        expect(subject).to receive(:validate_content_type_and_media_type!).with(@action).once
      end

      it "succeeds" do
        subject.validate(@action)
      end
    end
  end


  describe 'custom validate_xxx! methods' do
    before :each do
      allow(subject.class).to receive(:definition).and_return(response_spec)
    end

    describe "#validate_status!" do
      context 'that is completely valid' do
        it 'should succeed' do
          expect {
            subject.validate_status!
          }.to_not raise_error
        end
      end


      context 'with internal error' do
        let(:response_status) { 500 }
        it 'should raise an error that later gets swallowed' do
          expect {
            subject.validate_status!
          }.to raise_error(/Invalid response code detected./)
        end
      end

      context 'with incorrect response status' do
        let(:response_status) { 501 }
        it 'should raise an error' do
          expect {
            subject.validate_status!
          }.to raise_error(/Invalid response code detected/)
        end
      end

      context 'when no status is defined in the spec' do
        let(:spec_status)     { nil }
        let(:response_status) { 1234 }
        it 'skips any validation of it' do
          expect {
            subject.validate_status!
          }.to_not raise_error
        end
      end
    end



    describe "#validate_location!" do
      context 'checking location mismatches' do
        context 'for Regexp' do
          let(:spec_location) { /no_match/ }
          it 'should raise an error' do
            expect {
              subject.validate_location!
            }.to raise_error(/LOCATION does not match regexp/)
          end
        end

        context 'for String' do
          let(:spec_location) { "no_match" }
          it 'should raise error' do
            expect {
              subject.validate_location!
            }.to raise_error(/LOCATION does not match string/)
          end
        end

        context 'for any other type' do
          let(:spec_location) { Object }
          it 'should raise error' do
            expect {
              subject.validate_location!
            }.to raise_error(/Unknown location/)
          end
        end
      end
    end


    describe "#validate_location!" do
      context 'checking headers are set' do
        context 'when there are missing headers' do
          let (:spec_headers) { { 'X-some' => 'test' } }
          it 'should raise error' do
            expect {
              subject.validate_headers!
            }.to raise_error(/headers missing/)
          end
        end

        context "when headers specs are name strings" do
          context "and is missing" do
            let (:spec_headers) { [ "X-Just-Key" ] }
            it 'should raise error' do
              expect {
                subject.validate_headers!
              }.to raise_error(/headers missing/)
            end
          end

          context "and is not missing" do
            let (:spec_headers) { [ "X-Header" ] }
            it 'should not raise error' do
              expect {
                subject.validate_headers!
              }.not_to raise_error
            end
          end
        end

        context "when header specs are hashes" do
          context "and is missing" do
            let (:spec_headers) {
              [ { "X-Header" => "notfoodbar" } ]
            }
            it 'should raise error' do
              expect {
                subject.validate_headers!
              }.to raise_error(/headers missing/)
            end
          end

          context "and is not missing" do
            let (:spec_headers) {
              [ { "X-Header" => "Foobar" } ]
            }
            it 'should not raise error' do
              expect {
                subject.validate_headers!
              }.not_to raise_error
            end
          end
        end

        context "when header specs are of mixed type " do
          context "and is missing" do
            let (:spec_headers) {
              [ { "X-Header" => "Foobar" }, "not-gonna-find-me" ]
            }
            it 'should raise error' do
              expect {
                subject.validate_headers!
              }.to raise_error(/headers missing/)
            end
          end

          context "and is not missing" do
            let (:spec_headers) {
              [ { "X-Header" => "Foobar" }, "Content-Type" ]
            }
            it 'should not raise error' do
              expect {
                subject.validate_headers!
              }.not_to raise_error
            end
          end
        end
      end
    end


    describe "#validate_content_type_and_media_type!" do
      context 'checking content type' do
        context 'for :controller_defined spec' do
          let(:spec_media_type) { :controller_defined }

          context 'when controller does not define any' do
            let(:config_media_type) { nil }
            it 'should raise error' do
              expect {
                subject.validate_content_type_and_media_type!(action)
              }.to raise_error(/doesn't have any associated media_type/)
            end
          end

          context 'when controller defines one maching our returned mime_type' do
            let(:config_media_type) { application_vnd_resource_media_type }
            it 'should not raise error' do
              expect {
                subject.validate_content_type_and_media_type!(action)
              }.to_not raise_error
            end
          end

          context 'when controller defines one that does not match our returned mime_type' do
            let(:config_media_type) { application_none_media_type }
            it 'should raise error' do
              expect {
                subject.validate_content_type_and_media_type!(action)
              }.to raise_error(/Bad Content-Type/)
            end
          end
        end


        context 'for explicitly defined spec' do
          let(:response_headers) {
            { 'X-Header' => 'Foobar',
              'Location' => '/api/resources/123' }
          }

          context 'when content type does not match' do
            let(:config_media_type) { application_none_media_type }
            it 'should raise error telling you so' do
              expect {
                subject.validate_content_type_and_media_type!(action)
              }.to raise_error(/Bad Content-Type/)
            end
          end

          context 'when content type is not set' do
            it 'should still raise an error' do
              expect {
                subject.validate_content_type_and_media_type!(action)
              }.to raise_error(/Bad Content-Type/)
            end
          end
        end
      end
    end


    context 'with multipart definitions' do
      it 'has specs'
    end

  end
end
