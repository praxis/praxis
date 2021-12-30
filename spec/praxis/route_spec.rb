require 'spec_helper'

describe Praxis::Route do
  let(:verb) { 'GET' }
  let(:path) { '/base/stuff' }
  let(:prefixed_path) { '/stuff' }
  let(:version) { '1.0' }
  let(:options) { {} }

  subject(:route) { Praxis::Route.new(verb, path, version, prefixed_path: prefixed_path, **options) }

  its(:verb) { should be(verb) }
  its(:path) { should be(path) }
  its(:version) { should be(version) }
  its(:prefixed_path) { should eq(prefixed_path) }
  its(:options) { should eq(options) }

  it 'defaults version to "n/a"' do
    route = Praxis::Route.new(verb, path, **options)
    expect(route.version).to eq('n/a')
  end

  context '#describe' do
    subject(:description) { route.describe }
    it { should eq({ verb: verb, path: path, version: version }) }

    context 'with options' do
      let(:options) { { option: 'value' } }
      its([:options]) { should eq(options) }
    end
  end
end
