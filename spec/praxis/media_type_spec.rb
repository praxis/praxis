require 'spec_helper'

describe Praxis::MediaType do
  let(:owner_resource) { instance_double(Person, id: 100, name: /[:name:]/.gen, href: '/', links: ['one','two']) }
  let(:manager_resource) { instance_double(Person, id: 101, name: /[:name:]/.gen, href: '/', links: []) }
  let(:custodian_resource) { instance_double(Person, id: 102, name: /[:name:]/.gen, href: '/', links: []) }
  let(:residents_summary_resource) do
    instance_double(Person::CollectionSummary, href: "/people", size: 2)
  end

  let(:resource) do
    double('address',
      id: 1,
      name: 'Home',
      owner: owner_resource,
      manager: manager_resource,
      custodian: custodian_resource,
      residents_summary: residents_summary_resource
    )
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
        expect(address.links.caretaker.object).to be(resource.custodian)
      end

    end
  end



  context 'accessor methods' do
    subject(:address_klass) { address.class }

    context '#identifier' do
      context 'in praxis v0' do
        it 'should be a kind of String' do
          if Praxis::VERSION =~ /^0/
            expect(subject.identifier).to be_kind_of(String)
          else
            raise 'Please remove this spec which is no longer pertinent'
          end
        end
      end

      context 'in praxis v1.0 and beyond' do
        it 'should be a kind of Praxis::MediaTypeIdentifier' do
          pending('interface-breaking change') if Praxis::VERSION =~ /^0/
          expect(subject.identifier).to be_kind_of(Praxis::MediaTypeIdentifier)
        end
      end
    end

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

        it 'inherits types appropriately' do
          links_attribute = Address::Links.attributes
          expect(links_attribute[:owner].type).to be(Person)
          expect(links_attribute[:super].type).to be(Person)
          expect(links_attribute[:caretaker].type).to be(Person)
        end

        context 'loading returned values' do
          subject(:residents) { address.links.residents }
          let(:residents_summary_resource) do
            {href: "/people", size: 2}
          end

          its(:href) { should eq('/people') }
          its(:size) { should eq(2) }
        end
      end
    end
  end

  context "rendering" do
    subject(:output) { address.render(view: :default) }

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
        let(:output) { volume.render(view: :default) }
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


  context 'describing' do

    subject(:described){ Address.describe }

    its(:keys) { should match_array( [:attributes, :description, :display_name, :family, :id, :identifier, :key, :name, :views] ) }
    its([:attributes]) { should be_kind_of(::Hash) }
    its([:description]) { should be_kind_of(::String) }
    its([:display_name]) { should be_kind_of(::String) }
    its([:family]) { should be_kind_of(::String) }
    its([:id]) { should be_kind_of(::String) }
    its([:name]) { should be_kind_of(::String) }
    its([:identifier]) { should be_kind_of(::String) }
    its([:key]) { should be_kind_of(::Hash) }
    its([:views]) { should be_kind_of(::Hash) }

    its([:description]) { should eq(Address.description) }
    its([:display_name]) { should eq(Address.display_name) }
    its([:family]) { should eq(Address.family) }
    its([:id]) { should eq(Address.id) }
    its([:name]) { should eq(Address.name) }
    its([:identifier]) { should eq(Address.identifier.to_s) }
    it 'should include the defined views' do
      expect( subject[:views].keys ).to match( [:default, :master] )
    end
    it 'should include the defined attributes' do
      expect( subject[:attributes].keys ).to match( [:id, :name, :owner, :custodian, :residents, :residents_summary, :links] )
    end
  end

  context 'using blueprint caching' do
    it 'has specs'
  end

end
