# frozen_string_literal: true

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
    it { should be_kind_of(Array) }
    it { should have(1).item }

    context 'the parsed parts' do
      subject(:part) { parts.first }

      its(:name) { should eq 'destination_path' }
      its(:body) { should eq '/etc/defaults' }
    end
  end

  context 'with a file part' do
    before do
      text = MIME::Text.new('DOCKER_HOST=tcp://127.0.0.1:2375')
      form.add text, 'file', 'docker'
    end

    subject(:part) { parts.find { |p| p.name == 'file' } }
    # subject(:part_body) { part.body }

    its(:payload) { should be_kind_of(Tempfile) }
    its(:filename) { should eq('docker') }
    its(:name) { should eq('file') }

    context 'headers' do
      subject(:part_headers) { part.headers }
      its(['Content-Type']) { should eq('text/plain') }
      its(['Content-Disposition']) { should match(/filename=docker/) }
    end

    it 'saves the value to the tempfile' do
      expect(File.exist?(part.payload.path)).to be(true)

      part.payload.rewind
      expect(part.payload.read).to eq('DOCKER_HOST=tcp://127.0.0.1:2375')
    end
  end
end
