require 'spec_helper'

describe Praxis::Links do
  let(:owner_resource) do
    double('owner', id: 100, name: /[:name:]/.gen, href: '/')
  end

  let(:manager_resource) do
    double('manager', id: 101, name: /[:name:]/.gen, href: '/')
  end

  let(:resource) do
    double('address', id: 1, name: 'Home', owner: owner_resource, manager: manager_resource)
  end

  subject(:link) { described_class.for(Address) }

  it 'returns the link class for the media type if defined' do
    expect(link.for(Address)).to eq(link)
  end

  context 'rendering' do
    subject(:view) { link.view(:default) }

    its(:name)      { should eq(:default) }
    its(:schema)    { should eq(Address::Links) }
    its(:contents)  { should have_key(:owner) }
    its(:contents)  { should have_key(:super) }
  end

  context '.example' do
    subject(:example) { Address.example }

    its('links.owner') { should be(example.owner) }
    its('links.super') { should be(example.object.manager) }

    it 'does not respond to non-top-level attributes from links' do
      expect { example.super }.to raise_error(NoMethodError)
    end

    it 'responds to non-top-level attributes from links on its inner Struct' do
      expect(example.links.super).to be(example.object.manager)
    end
  end
end
