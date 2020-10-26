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
    subject(:output) { address.render(view: :default) }

    its([:id])    { should eq(address.id) }
    its([:name])  { should eq(address.name) }
    its([:owner]) { should eq(Person.dump(owner_resource, view: :default)) }
    its([:fields]) { should eq(address.fields.dump ) }

  end

  context 'describing' do

    subject(:described){ Address.describe }

    its(:keys) { should match_array( [:attributes, :description, :display_name, :family, :id, :identifier, :key, :name, :views, :requirements] ) }
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
      expect( subject[:views].keys ).to match_array([:default, :master])
    end
    it 'should include the defined attributes' do
      expect( subject[:attributes].keys ).to match_array([:id, :name, :owner, :custodian, :residents, :residents_summary, :fields])
    end
  end

  context 'using blueprint caching' do
    it 'has specs'
  end

  context Praxis::MediaType::FieldResolver do
    let(:expander) { Praxis::FieldExpander }
    let(:user_view) { User.views[:default] }

    let(:fields) { expander.expand(user_view) }

    let(:field_resolver) { Praxis::MediaType::FieldResolver }

    subject(:output) { field_resolver.resolve(User,fields) }

    context 'resolving collections' do
      let(:fields) { {:id=>true, :posts=>[{:href=>true}]}}
      it 'strips arrays from the incoming fields' do
        expect(output).to eq(id: true, posts: {href: true})
      end

      it 'supports multi-dimensional collections' do
        fields = {
          id: true,
          post_matrix:[[{title: true, href: true}]]
        }
        output = field_resolver.resolve(User,fields)
        expect(output).to eq(id: true, post_matrix:{href: true, title: true})
      end

      it 'supports nesting structs and arrays collections' do
        fields = {
         id: true,
         daily_posts: [
           {day: true, posts: [{id: true}]}
         ]
        }
        output = field_resolver.resolve(User,fields)
        expect(output).to eq(id: true, daily_posts:{day: true, posts: {id:true}})
      end
    end

  end


end
