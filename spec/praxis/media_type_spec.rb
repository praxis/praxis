# frozen_string_literal: true

require 'spec_helper'

describe Praxis::MediaType do
  let(:owner_resource) { instance_double(Person, id: 100, name: Faker::Name.first_name, href: '/') }
  let(:manager_resource) { instance_double(Person, id: 101, name: Faker::Name.first_name, href: '/') }
  let(:custodian_resource) { instance_double(Person, id: 102, name: Faker::Name.first_name, href: '/') }
  let(:residents_summary_resource) do
    instance_double(Person::CollectionSummary, href: '/people', size: 2)
  end

  let(:resource) do
    double('address',
           id: 1,
           name: 'Home',
           owner: owner_resource,
           manager: manager_resource,
           custodian: custodian_resource,
           residents_summary: residents_summary_resource,
           fields: { id: true, name: true })
  end

  subject(:address) { Address.new(resource) }

  context 'attributes' do
    its(:id)    { should eq(1) }
    its(:name)  { should eq('Home') }
    its(:owner) { should be_instance_of(Person) }
  end

  context 'accessor methods' do
    subject(:address_klass) { address.class }

    context '#identifier' do
      it 'should be a kind of Praxis::MediaTypeIdentifier' do
        expect(subject.identifier).to be_kind_of(Praxis::MediaTypeIdentifier)
      end
    end

    its(:description) { should be_kind_of(String) }
  end

  context 'rendering' do
    subject(:output) { address.render }

    its([:id])    { should eq(address.id) }
    its([:name])  { should eq(address.name) }
    its([:owner]) { should eq(Person.dump(owner_resource)) }
    its([:fields]) { should eq(address.fields.dump) }
  end
end
