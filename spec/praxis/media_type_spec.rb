require 'spec_helper'

describe Praxis::MediaType do
  let(:owner_resource) { instance_double(Person, id: 100, name: /[:name:]/.gen, href: '/') }
  let(:manager_resource) { instance_double(Person, id: 101, name: /[:name:]/.gen, href: '/') }
  let(:custodian_resource) { instance_double(Person, id: 102, name: /[:name:]/.gen, href: '/') }
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
      residents_summary: residents_summary_resource,
      fields: {id: true, name: true}
    )
  end

  subject(:address) { Address.new(resource) }


  context 'attributes' do
    its(:id)    { should eq(1) }
    its(:name)  { should eq('Home') }
    its(:owner) { should be_instance_of(Person) }
  end


  context 'loading' do
    it do
      Person.load({id: 1})
      Person.load(owner_resource)

    end
  end


  context 'accessor methods' do
    subject(:address_klass) { address.class }

    context '#identifier' do
      context 'in praxis v1.0 and beyond' do
        it 'should be a kind of Praxis::MediaTypeIdentifier' do
          pending('interface-breaking change') if Praxis::VERSION =~ /^0/
          expect(subject.identifier).to be_kind_of(Praxis::MediaTypeIdentifier)
        end
      end
    end

    its(:description) { should be_kind_of(String) }

  end

  context "rendering" do
    subject(:output) { address.render }

    its([:id])    { should eq(address.id) }
    its([:name])  { should eq(address.name) }
    its([:owner]) { should eq(Person.dump(owner_resource)) }
    its([:fields]) { should eq(address.fields.dump ) }

  end

  context 'describing' do

    subject(:described){ Address.describe }

    its(:keys) { should match_array( [:attributes, :description, :display_name, :family, :id, :identifier, :key, :name, :requirements] ) }
    its([:attributes]) { should be_kind_of(::Hash) }
    its([:description]) { should be_kind_of(::String) }
    its([:display_name]) { should be_kind_of(::String) }
    its([:family]) { should be_kind_of(::String) }
    its([:id]) { should be_kind_of(::String) }
    its([:name]) { should be_kind_of(::String) }
    its([:identifier]) { should be_kind_of(::String) }
    its([:key]) { should be_kind_of(::Hash) }

    its([:description]) { should eq(Address.description) }
    its([:display_name]) { should eq(Address.display_name) }
    its([:family]) { should eq(Address.family) }
    its([:id]) { should eq(Address.id) }
    its([:name]) { should eq(Address.name) }
    its([:identifier]) { should eq(Address.identifier.to_s) }

    it 'should include the defined attributes' do
      expect( subject[:attributes].keys ).to match_array([:id, :name, :owner, :custodian, :residents, :residents_summary, :fields])
    end
  end

  context 'using blueprint caching' do
    it 'has specs'
  end
end
