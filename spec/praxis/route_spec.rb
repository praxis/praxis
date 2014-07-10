require 'spec_helper'

describe Praxis::Route do

  let(:verb) { 'GET' }
  let(:path) { '/stuff' }
  let(:name) { nil }
  let(:version) { '1.0' }
  let(:options) { {} }

  subject(:route) { Praxis::Route.new(verb, path, version, name: name, **options) }

  its(:verb) { should be(verb) }
  its(:path) { should be(path) }
  its(:name) { should be(name) }
  its(:version) { should be(version) }
  its(:options) { should eq(options) }

  it 'defaults version to "n/a"' do
    route = Praxis::Route.new(verb, path, name: name, **options)
    expect(route.version).to eq('n/a')
  end

  context '#describe' do
    subject(:description) { route.describe }
    it { should eq({verb:verb, path:path , version:version}) }

    context 'with a named route' do
      let(:name) { :stuff }
      its([:name]) { should eq(name) }
    end

    context 'with options' do
      let(:options) { {option: 'value'} }
      its([:options]) { should eq(options) }
    end

  end



end
