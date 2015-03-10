require 'spec_helper'

describe Praxis::MediaType do
  let(:owner_resource) { instance_double(Person, id: 100, name: /[:name:]/.gen, href: '/', links: ['one','two']) }
  let(:manager_resource) { instance_double(Person, id: 101, name: /[:name:]/.gen, href: '/', links: []) }

  let(:resource) do
    double('address', id: 1, name: 'Home',owner: owner_resource, manager: manager_resource)
  end

  subject(:address) { Address.new(resource) }


  context 'attributes' do
    its(:id)    { should eq(1) }
    its(:name)  { should eq('Home') }
    its(:owner) { should be_instance_of(Person) }

    context 'links' do
      it 'respects using' do
        expect(address.links.super).to be_kind_of(Person)
        expect(address.links.super.object).to be(resource.manager)
      end
    end
  end


  
  context 'accessor methods' do
    subject(:address_klass) { address.class }

    its(:identifier)  { should be_kind_of(String) }
    its(:description) { should be_kind_of(String) }
    
    context 'links' do
      context 'with a custom links attribute' do
        subject(:person) { Person.new(owner_resource) }

        its(:links)  { should be_kind_of(Array) }
        its(:links)  { should eq(owner_resource.links) }
      end
  
      context 'using the links DSL' do
        subject(:address) { Address.new(resource) }
        its(:links)  { should be_kind_of(Address::Links) }
      end
      
    end
  end

  context "rendering" do
    subject(:output) { address.render(:default) }

    its([:id])    { should eq(address.id) }
    its([:name])  { should eq(address.name) }
    its([:owner]) { should eq(Person.dump(owner_resource, view: :default)) }


    context 'links' do
      subject(:links) { output[:links] }

      its([:owner]) { should eq(Person.dump(owner_resource, view: :link)) }
      its([:super]) { should eq(Person.dump(manager_resource, view: :link)) }

      context 'for a collection summary' do
        let(:volume) { Volume.example }
        let(:snapshots_summary) { volume.snapshots_summary }
        let(:output) { volume.render(:default) }
        subject { links[:snapshots] }
             
        its([:name]) { should eq(snapshots_summary.name) }
        its([:size]) { should eq(snapshots_summary.size) }
        its([:href]) { should eq(snapshots_summary.href) }
      end
    end


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


  context 'using blueprint caching' do
    it 'has specs'
  end

end
