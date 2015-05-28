require "spec_helper"

describe Praxis::Multipart do
  let(:type) { Praxis::Multipart }

  let(:form) do
    form_data = MIME::Multipart::FormData.new
    entity = MIME::Text.new('1')
    form_data.add entity,'some_name'
    form_data
  end

  let(:content_type) { form.headers.get('Content-Type') }
  let(:body) { form.body.to_s }

  subject(:multipart) { type.load(body, content_type: content_type) }

  context 'with no block' do
    its(:parts) { should have(1).item }
    its(['some_name']) { should eq('1') }
  end

  context 'with value type' do
    let(:type) { Praxis::Multipart.of(value: Integer) }
    its(['some_name']) { should eq(1) }
  end


  context 'with a block' do

    let(:block) do
      proc do
        key 'some_name', Integer
        key 'some_date', DateTime
      end
    end

    let(:date) { DateTime.parse("2014-07-15") }

    before do
      entity = MIME::Text.new(date)
      form.add entity,'some_date'
    end

    let(:type) { Praxis::Multipart.construct(block) }

    its(['some_name']) { should eq(1) }
    its(['some_date']) { should eq(date) }

  end


  context 'with a preamble' do
    let(:preamble) { "some preamble"}
    let(:body) { preamble + "\r\n" + form.body.to_s }

    it 'preserves the value' do
      expect(multipart.preamble).to eq(preamble)
    end

  end

  context '.example' do
    let(:type) { Praxis::Multipart.of(value: Instance) }
    subject(:example) { type.example('example') }

    it 'generates an interesting example' do
      expect(example.keys.all? { |k| k.kind_of? String }).to be(true)
      expect(example.values.all? { |k| k.kind_of? Instance }).to be(true)
      expect(example.parts.keys).to eq(example.keys.collect(&:to_s))


      instance = Instance.load(example.parts.first.last.body)
      expect(instance.validate).to be_empty

      expect(example.headers['Content-Type']).to match(/multipart\/form-data; boundary=/)
    end

  end

  context '.load' do
    it 'returns nil when loading nil' do
      expect(type.load(nil)).to be nil
    end
    it 'returns the same value when loading an instance of a Multipart class' do
      instance = Praxis::Multipart.example
      expect(type.load(instance)).to be instance
    end

    it 'complains when the value is not a String (besides a Multipart instance or nil)' do
       expect{
        type.load( {a: "hash"} )
        }.to raise_error(Attributor::CoercionError)
    end

    pending 'complete the load tests'
  end

  context '#describe' do
    subject(:described) { type.describe }
    its([:family]){ should eq('multipart')}
  end
end
