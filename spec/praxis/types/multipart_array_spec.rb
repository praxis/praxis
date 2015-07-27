require "spec_helper"

describe Praxis::Types::MultipartArray do

  let(:type) do
    Class.new(Praxis::Types::MultipartArray) do
      self.options[:case_insensitive_load] = true

      part 'title', String, required: true
      part(/nam/, String, regexp: /Bob/i)

      part /stuff/ do
        payload Hash
      end

      file 'files', multiple: true do
        header 'Content-Type', 'application/octet-stream'
        filename String, regexp: /file/
        payload Attributor::Tempfile
      end

      part 'image', Attributor::Tempfile, filename: true

    end
  end


  let(:form) do
    form_data = MIME::Multipart::FormData.new
    entity = MIME::Text.new('Bob')
    form_data.add entity,'name'

    entity = MIME::Text.new('Captain')
    form_data.add entity,'title'

    entity = MIME::Application.new('file1')
    form_data.add entity,'files', 'file1'

    entity = MIME::Application.new('file2')
    form_data.add entity,'files', 'file2'

    entity = MIME::Application.new('
      <?xml version="1.0" encoding="UTF-8"?>
      <hash>
        <first_name>James</first_name>
      </hash>
      ', 'xml')
    form_data.add entity,'stuff1'

    entity = MIME::Application.new('{"first_name": "Frank"}', 'json')
    form_data.add entity,'stuff2'

    entity = MIME::Application.new('', 'jpg')
    form_data.add entity,'image', 'image.jpg'

    form_data
  end

  let(:content_type) { form.headers.get('Content-Type') }
  let(:body) { form.body.to_s }

  subject(:payload) { type.load(body, content_type: content_type) }

  it 'validates' do
    part = payload.part('files').first
    expect(payload.validate).to be_empty
  end

  it 'loads parts correctly' do
    expect(payload.part('name')).to be_kind_of(Praxis::MultipartPart)
    expect(payload.part('name').payload).to eq 'Bob'

    title = payload.part('title')
    expect(title.payload).to eq 'Captain'

    files = payload.part('files')
    expect(files).to have(2).items

    stuff1 = payload.part('stuff1')
    expect(stuff1.payload['first_name']).to eq 'James'

    stuff2 = payload.part('stuff2')
    expect(stuff2.payload['first_name']).to eq 'Frank'

    image = payload.part('image')
    expect(image.filename).to eq 'image.jpg'
  end

  context 'with only payload_type defined' do
    let(:type) do
      Class.new(Praxis::Types::MultipartArray) do
        name_type String
        payload_type Hash do
          key 'sub_hash', Hash
        end
      end
    end

    let(:json_payload) { {sub_hash: {key:'value'}}.to_json }
    let(:body) { StringIO.new("--boundary\r\nContent-Disposition: form-data; name=blah\r\n\r\n#{json_payload}\r\n--boundary--") }
    let(:content_type) { "multipart/form-data; boundary=boundary" }

    it do
      expect(payload.part('blah').payload['sub_hash']).to eq('key' => 'value')
    end
  end

  context 'with simple payload_type block defined' do
    let(:type) do
      Class.new(Praxis::Types::MultipartArray) do
        name_type String
        payload_type do
          attribute :attr, String
        end
      end
    end

    let(:json_payload) { {attr: 'value'}.to_json }
    let(:body) { StringIO.new("--boundary\r\nContent-Disposition: form-data; name=blah\r\n\r\n#{json_payload}\r\n--boundary--") }
    let(:content_type) { "multipart/form-data; boundary=boundary" }

    it do
      expect(payload.part('blah').payload.class.ancestors).to include(Attributor::Struct)
      expect(payload.part('blah').payload.attr).to eq('value')
    end
  end

  context '.describe' do
    subject(:description) { type.describe(false) }

    its([:name]) { should eq 'Praxis::Types::MultipartArray' }

    it { should have_key :part_name }
    it { should have_key :attributes }
    it { should have_key :pattern_attributes }

    context 'attributes' do
      subject(:attributes) { description[:attributes] }
      its(:keys) { should match_array ['title', 'files', 'image']}

      context 'the "title" part' do
        subject(:title_description) { attributes['title'] }

        it 'describes the options' do
          expect(title_description[:options][:required]).to be true
        end

        it 'describes the payload' do
          expect(title_description[:type][:payload][:type]).to eq Attributor::String.describe
        end
      end

      context 'the "files" part' do
        subject(:files_description) { attributes['files'] }

        it 'describes the options' do
          expect(files_description[:options][:multiple]).to be true
        end

        it 'describes the payload' do
          expect(files_description[:type][:payload][:type]).to eq Attributor::Tempfile.describe
        end

        it 'describes the filename' do
          filename = files_description[:type][:filename]
          expect(filename[:options]).to eq(regexp: /file/)
          expect(filename[:type]).to eq Attributor::String.describe
        end

      end
    end

    context 'pattern attributes' do
      subject(:pattern_attributes) { description[:pattern_attributes] }
      its(:keys) { should match_array ['nam', 'stuff']}
    end

    context 'with no parts defined' do
      let(:type) do
        Class.new(Praxis::Types::MultipartArray) do
          name_type DateTime
          payload_type Hash
        end
      end
      its([:name]) { should eq 'Praxis::Types::MultipartArray' }

      it { should_not have_key :attributes }
      it { should_not have_key :pattern_attributes }

      it { should have_key :part_name }
      it { should have_key :part_payload }
    end

    context 'with an example passed in' do
      let(:example) { type.example }
      subject(:description) { type.describe(false, example: example) }

      it 'uses the example values' do
        expect(
          description[:attributes]['title'][:type][:payload][:example]
        ).to eq example.part('title').payload

        file_example = example.part('files').first.payload
        file_example.rewind
        expect(
          description[:attributes]['files'][:type][:payload][:example]
        ).to eq file_example.read

        image_example = example.part('image').payload
        image_example.rewind
        expect(
          description[:attributes]['image'][:type][:payload][:example]
        ).to eq image_example.read
      end
    end
  end

  context 'dumping' do
    subject(:dumped) { payload.dump }

    it 'dumps' do
      loaded = type.load(dumped, content_type: payload.content_type)
    end
    context 'an example' do
      let(:payload) { type.example }

      it 'dumps' do
        loaded = type.load(dumped, content_type: payload.content_type)
      end
    end
  end

  context 'with errors' do
    let(:form) do
      form_data = MIME::Multipart::FormData.new

      entity = MIME::Text.new('James')
      form_data.add entity,'name'


      entity = MIME::Text.new('file1')
      form_data.add entity,'files', 'file1'

      form_data
    end

    subject(:errors) { payload.validate }

    it 'validates part headers' do
      expect(errors).to have(3).items
      expect(errors).to match_array([
                                      %r|\.name\.payload value .* does not match regexp|,
                                      %r|\.files\.headers.* is not within the allowed values|,
                                      %r|\.title is required|
      ])
    end
  end

  context '.example' do
    subject(:payload) { type.example }

    it 'generates parts' do
      title = payload.part('title')
      expect(title).to_not be_nil
      expect(title.payload).to match /\w+/

      files = payload.part('files')
      expect(files).to have(2).items

      files.each do |file|
        expect(file.payload).to be_kind_of(Tempfile)
        expect(file.filename).to match /\w+/

        expect(file.headers['Content-Type']).to eq 'application/octet-stream'
      end
    end

    it 'is valid' do
      expect(payload.validate).to have(0).items
    end

  end

  context 'with a hackish default part definition' do
    let(:type) do
      Class.new(Praxis::Types::MultipartArray) do
        self.options[:case_insensitive_load] = true

        part /\d+/, Instance
      end
    end

    let(:form) do
      form_data = MIME::Multipart::FormData.new

      (1..5).each do |i|
        instance = Instance.example("instance-#{i}")
        body = JSON.pretty_generate(instance.render)
        entity = MIME::Text.new(body)
        form_data.add entity,i.to_s
      end

      form_data
    end

    it 'loads the parts as the proper type' do
      payload.each do |part|
        expect(part.payload).to be_kind_of(Instance)
      end
    end

  end


  context 'anonymous generation' do
    let(:definition_block) do
      proc do
        name_type Integer
        payload_type Instance
      end
    end

    let(:attribute) do
      Attributor::Attribute.new(Praxis::Types::MultipartArray, &definition_block)
    end

    let(:form) do
      form_data = MIME::Multipart::FormData.new

      (1..5).each do |i|
        instance = Instance.example("instance-#{i}")
        body = JSON.pretty_generate(instance.render)
        entity = MIME::Text.new(body)
        form_data.add entity,i.to_s
      end

      form_data
    end

    let(:payload) { attribute.load(body, content_type: content_type) }

    it 'loads the parts as the proper type' do
      expect(payload).to have(5).items
      payload.each do |part|
        expect(part.name).to be_kind_of(Integer)
        expect(part.payload).to be_kind_of(Instance)
      end
    end


  end


end
