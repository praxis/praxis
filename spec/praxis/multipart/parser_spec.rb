require 'spec_helper'

describe Praxis::MultipartParser do

  let(:form) do
    form_data = MIME::Multipart::FormData.new

    destination_path = MIME::Text.new('/etc/defaults')
    form_data.add destination_path, 'destination_path'

    form_data
  end

  let(:headers) { form.headers.headers }
  let(:body) { form.body.to_s }

  let(:parser) { Praxis::MultipartParser.new(headers, body) }

  subject(:parts) { parser.parse[1] }

  context 'with simple parts' do
    it { should have(1).item }
    it { should have_key('destination_path') }

    it 'sets the right values on the part' do
      expect(parts['destination_path'].body).to eq('/etc/defaults')
    end
  end

  context 'with a file part' do
    before do
      text = MIME::Text.new('DOCKER_HOST=tcp://127.0.0.1:2375')
      form.add text, 'file', 'docker'
    end

    subject(:file_part_body) { parts['file'].body }

    it { should be_kind_of(Hash) }
    its([:filename]) { should eq("docker") }
    its([:name]) { should eq("file") }
    its([:type]) { should eq("text/plain") }
    its([:tempfile]) { should be_kind_of(Tempfile)}
    its([:head]) { should match(/Content-Disposition/) } 

    it 'saves the value to the tempfile' do
      expect(File.exist?(file_part_body[:tempfile].path)).to be(true)

      file_part_body[:tempfile].rewind
      expect(file_part_body[:tempfile].read).to eq('DOCKER_HOST=tcp://127.0.0.1:2375')
    end

  end

end
