# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

describe Praxis::Blueprint do
  subject(:blueprint_class) { PersonBlueprint }

  its(:family) { should eq('hash') }

  # This context might seem a duplication of tests that should be covered by the underlying attributor gem
  # but while it is in structure, it is different because we're doing it with Blueprints (not Attributor Models)
  # to make sure our Blueprints are behaving as expected.
  context 'type resolution, option inheritance for attributes with and without references' do
    # Overall strategy
    # 1) When no type is specified:
    #   1.1) if it is a leaf (no block)
    #     1.1.1) with an reference with an attr with the same name
    #          - type copied from reference
    #          - reference options are inherited as well (and can be overridden by local attribute ones)
    #     1.1.2) without a ref (or the ref does not have same attribute name)
    #          - Fail. Cannot determine type
    #   1.2) if it has a block
    #     1.2.1) with an reference with an attr with the same name
    #          - We assume you're re/defining a new Struct (or Struct[]), and we will incorporate the reference type
    #           for the matching name in case you are indeed redefining a subset of the attributes, so you can enjoy inheritance
    #     1.2.2) without a ref (or the ref does not have same attribute name)
    #          - defaulted to Struct (if you meant Collection.of(Struct) things would fail later somehow)
    #          - options are NOT inherited at all (This is something we should ponder more about)
    # 2) When type is specified:
    #   2.1) if it is a leaf (no block)
    #     - ignore ref if there is one (with or without matching attribute name).
    #     - simply use provided type, and provided options (no inheritance)
    #   2.2) if it has a block
    #     - Same as above: use type and options provided, ignore ref if there is one (with or without matching attribute name).

    let(:mytype) do
      Praxis::Blueprint.finalize!
      Class.new(Praxis::Blueprint, &myblock).tap(&:_finalize!)
    end
    context 'with no explicit type specified' do
      context 'without a block (if it is a leaf)' do
        context 'that has a reference with an attribute with the same name' do
          let(:myblock) do
            proc do
              attributes reference: PersonBlueprint do
                attribute :age, required: true, min: 42
              end
            end
          end
          it 'uses type from reference' do
            expect(mytype.attributes).to have_key(:age)
            expect(mytype.attributes[:age].type).to eq(PersonBlueprint.attributes[:age].type)
          end
          it 'copies over reference options and allows the attribute to override/add some' do
            merged_options = PersonBlueprint.attributes[:age].options.merge(required: true, min: 42)
            expect(mytype.attributes[:age].options).to include(merged_options)
          end
        end
        context 'with a reference, but that does not have a matching attribute name' do
          let(:myblock) do
            proc do
              attributes reference: AddressBlueprint do
                attribute :age
              end
            end
          end
          it 'fails resolving' do
            expect { mytype.attributes }.to raise_error(/Type for attribute with name: age could not be determined./)
          end
        end
        context 'without a reference' do
          let(:myblock) do
            proc do
              attributes do
                attribute :age
              end
            end
          end
          it 'fails resolving' do
            expect { mytype.attributes }.to raise_error(/Type for attribute with name: age could not be determined./)
          end
        end
      end
      context 'with block (if it is NOT a leaf)' do
        context 'that has a reference with an attribute with the same name' do
          context 'which is not a collection type' do
            let(:myblock) do
              proc do
                attributes reference: PersonBlueprint do
                  attribute :age, description: 'I am fully redefining' do
                    attribute :foobar, Integer, min: 42
                  end
                end
              end
            end
            it 'picks Struct, and makes sure to pass the reference of the attribute along' do
              expect(mytype.attributes).to have_key(:age)
              age_attribute = mytype.attributes[:age]
              # Resolves to Struct
              expect(age_attribute.type).to be < Attributor::Struct
              # does NOT brings any ref options (except the right reference)
              expect(age_attribute.options).to include(description: 'I am fully redefining')
              # Yes, there is no way we can ever use an Integer when we're defining a Struct...but if the parent was a Struct, we would
              expect(age_attribute.options).to include(reference: Attributor::Integer)
              # And the nested attribute is correctly resolved as well, and ensures options are there
              expect(age_attribute.type.attributes[:foobar].type).to eq(Attributor::Integer)
              expect(age_attribute.type.attributes[:foobar].options).to eq(min: 42)
            end
          end
          context 'which is a collection type' do
            let(:myblock) do
              proc do
                attributes reference: PersonBlueprint do
                  attribute :prior_addresses, description: 'I am fully redefining' do
                    attribute :street, required: true
                    attribute :new_attribute, String, default: 'foo'
                  end
                end
              end
            end
            it 'picks Struct, and makes sure to pass the reference of the attribute along' do
              expect(mytype.attributes).to have_key(:prior_addresses)
              prior_addresses_attribute = mytype.attributes[:prior_addresses]
              # Resolves to Struct[]
              expect(prior_addresses_attribute.type).to be < Attributor::Collection
              expect(prior_addresses_attribute.type.member_type).to be < Attributor::Struct
              # does NOT brings any ref options (except the right reference)
              expect(prior_addresses_attribute.options).to include(description: 'I am fully redefining')
              # Yes, there is no way we can ever use an Integer when we're defining a Struct...but if the parent was a Struct, we would
              expect(prior_addresses_attribute.options).to include(reference: PersonBlueprint.attributes[:prior_addresses].type.member_type)
              # And the nested attributes are correctly resolved as well, and ensures options are there
              street_options_from_ref = PersonBlueprint.attributes[:prior_addresses].type.member_type.attributes[:street].options
              expect(prior_addresses_attribute.type.member_type.attributes[:street].type).to eq(Attributor::String)
              expect(prior_addresses_attribute.type.member_type.attributes[:street].options).to eq(street_options_from_ref.merge(required: true))

              expect(prior_addresses_attribute.type.member_type.attributes[:new_attribute].type).to eq(Attributor::String)
              expect(prior_addresses_attribute.type.member_type.attributes[:new_attribute].options).to eq(default: 'foo')
            end
          end
          context 'in the unlikely case that the reference type has an anonymous Struct (or collection of)' do
            let(:myblock) do
              proc do
                attributes reference: PersonBlueprint do
                  attribute :funny_attribute, description: 'Funny business' do
                    attribute :foobar, Integer, min: 42
                  end
                end
              end
            end
            it 'correctly inherits it (same result as defaulting to Struct) and brings in the reference' do
              expect(mytype.attributes).to have_key(:funny_attribute)
              # Resolves to Struct, and brings (and merges) the ref options with the attribute's
              expect(mytype.attributes[:funny_attribute].type).to be < Attributor::Struct
              merged_options = { reference: PersonBlueprint.attributes[:funny_attribute].type }.merge(description: 'Funny business')
              expect(mytype.attributes[:funny_attribute].options).to include(merged_options)
              # And the nested attribute is correctly resolved as well, and ensures options are there
              expect(mytype.attributes[:funny_attribute].type.attributes[:foobar].type).to eq(Attributor::Integer)
              expect(mytype.attributes[:funny_attribute].type.attributes[:foobar].options).to eq(min: 42)
            end
          end
        end
        context 'with a reference, but that does not have a matching attribute name' do
          let(:myblock) do
            proc do
              attributes reference: AddressBlueprint do
                attribute :age, description: 'I am redefining' do
                  attribute :foobar, Integer, min: 42
                end
              end
            end
          end
          it 'correctly defaults to Struct uses only the local options (same exact as if it had no reference)' do
            expect(mytype.attributes).to have_key(:age)
            age_attribute = mytype.attributes[:age]
            # Resolves to Struct
            expect(age_attribute.type).to be < Attributor::Struct
            # does NOT brings any ref options
            expect(age_attribute.options).to  eq(description: 'I am redefining')
            # And the nested attribute is correctly resolved as well, and ensures options are there
            expect(age_attribute.type.attributes[:foobar].type).to eq(Attributor::Integer)
            expect(age_attribute.type.attributes[:foobar].options).to eq(min: 42)
          end
        end
        context 'without a reference' do
          let(:myblock) do
            proc do
              attributes do
                attribute :age, description: 'I am redefining' do
                  attribute :foobar, Integer, min: 42
                end
              end
            end
          end
          it 'correctly defaults to Struct uses only the local options' do
            expect(mytype.attributes).to have_key(:age)
            age_attribute = mytype.attributes[:age]
            # Resolves to Struct
            expect(age_attribute.type).to be < Attributor::Struct
            # does NOT brings any ref options
            expect(age_attribute.options).to  eq(description: 'I am redefining')
            # And the nested attribute is correctly resolved as well, and ensures options are there
            expect(age_attribute.type.attributes[:foobar].type).to eq(Attributor::Integer)
            expect(age_attribute.type.attributes[:foobar].options).to eq(min: 42)
          end
        end
      end
    end
    context 'with an explicit type specified' do
      context 'without a reference' do
        let(:myblock) do
          proc do
            attributes do
              attribute :age, String, description: 'I am a String now'
            end
          end
        end
        it 'always uses the provided type and local options specified' do
          expect(mytype.attributes).to have_key(:age)
          age_attribute = mytype.attributes[:age]
          # Resolves to String
          expect(age_attribute.type).to eq(Attributor::String)
          # copies local options
          expect(age_attribute.options).to eq(description: 'I am a String now')
        end
      end
      context 'with a reference' do
        let(:myblock) do
          proc do
            attributes reference: PersonBlueprint do
              attribute :age, String, description: 'I am a String now'
            end
          end
        end
        it 'always uses the provided type and local options specified (same as if it had no reference)' do
          expect(mytype.attributes).to have_key(:age)
          age_attribute = mytype.attributes[:age]
          # Resolves to String
          expect(age_attribute.type).to eq(Attributor::String)
          # copies local options
          expect(age_attribute.options).to eq(description: 'I am a String now')
        end
      end

      context 'with a reference, which can further percolate down' do
        let(:myblock) do
          proc do
            attributes reference: PersonBlueprint do
              attribute :age, String, description: 'I am a String now'
              attribute :address, Struct, description: 'Address subset' do
                attribute :street, required: true
              end
              attribute :tags
            end
          end
        end

        it 'brings the child reference for address so we can redefine it' do
          expect(mytype.attributes.keys).to eq(%i[age address tags])
          age_attribute = mytype.attributes[:age]
          expect(age_attribute.type).to eq(Attributor::String)
          expect(age_attribute.options).to eq(description: 'I am a String now')

          address_attribute = mytype.attributes[:address]
          expect(address_attribute.type).to be < Attributor::Struct
          # It brings in our local options AND percolates down the reference type for address
          expect(address_attribute.options).to include(description: 'Address subset', reference: AddressBlueprint)

          # Address fields are properly resolved to match the corresponding AddressBlueprint
          expect(address_attribute.type.attributes.keys).to eq([:street])
          street_attribute = address_attribute.type.attributes[:street]
          expect(street_attribute.type).to eq(AddressBlueprint.attributes[:street].type)
          # Makes sure our local options on the street are kept
          expect(street_attribute.options).to include(required: true)
          # And brings in other options from the inherited street attribute
          expect(street_attribute.options).to include(description: 'The street')

          # It also properly resolves the direct tags attribute from the reference, pointing to the same type
          tags_attribute = mytype.attributes[:tags]
          expect(tags_attribute.type).to eq PersonBlueprint.attributes[:tags].type
        end
      end
    end
  end
  context 'deterministic examples' do
    it 'works' do
      person1 = PersonBlueprint.example('person 1')
      person2 = PersonBlueprint.example('person 1')

      expect(person1.name).to eq(person2.name)
      expect(person1.address.name).to eq(person2.address.name)
    end
  end

  context 'implicit default_fieldset (when not defined in the blueprint)' do
    subject(:default_fieldset) { AddressBlueprint.default_fieldset }

    it { should_not be(nil) }
    it 'contains all attributes' do
      simple_attributes = %i[id name street state]
      expect(default_fieldset.keys).to match_array(simple_attributes)
      # Should not have blueprint-derived attributes (or collections of them)
      expect(default_fieldset.keys).to_not include(AddressBlueprint.attributes.keys - simple_attributes)
    end
  end

  context 'creating a new Blueprint class' do
    subject!(:blueprint_class) do
      Class.new(Praxis::Blueprint) do
        domain_model Hash
        attributes do
          attribute :id, Integer
        end
      end
    end

    its(:finalized?) { should be(false) }
    its(:domain_model) { should be(Hash) }

    context '.finalize on Praxis::Blueprint' do
      before do
        expect(blueprint_class).to receive(:_finalize!).and_call_original
        Praxis::Blueprint.finalize!
      end

      its(:finalized?) { should be(true) }
    end

    context '.finalize on that subclass' do
      before do
        expect(blueprint_class).to receive(:_finalize!).and_call_original
        blueprint_class.finalize!
      end

      its(:finalized?) { should be(true) }
    end
  end

  context 'creating a base abstract Blueprint class without attributes' do
    subject!(:blueprint_class) do
      Class.new(Praxis::Blueprint)
    end

    it 'skips attribute definition' do
      expect(blueprint_class).to receive(:_finalize!).and_call_original
      expect(blueprint_class).to_not receive(:define_attribute)
      blueprint_class.finalize!
      expect(blueprint_class.finalized?).to be(true)
    end
  end

  it 'has an inner Struct class for the attributes' do
    expect(blueprint_class.attribute.type).to be blueprint_class::InnerStruct
  end

  context 'an instance' do
    shared_examples 'a blueprint instance' do
      let(:expected_name) { blueprint_instance.name }

      context '#render' do
        subject(:output) { blueprint_instance.render }

        it { should have_key(:name) }
        it 'has the right values' do
          expect(subject[:name]).to eq(expected_name)
        end
      end

      context 'validation' do
        subject(:errors) { blueprint_class.validate(blueprint_instance) }
        it { should be_empty }
      end
    end

    context 'from Blueprint.example' do
      subject(:blueprint_instance) do
        blueprint_class.example('ExamplePersonBlueprint',
                                address: nil,
                                prior_addresses: [],
                                work_address: nil,
                                myself: nil,
                                friends: [])
      end
      it_behaves_like 'a blueprint instance'
    end

    context 'wrapping an object' do
      let(:data) do
        {
          name: 'Bob',
          full_name: FullName.example,
          address: nil,
          email: 'bob@example.com',
          aliases: [],
          prior_addresses: [],
          parents: { father: Randgen.first_name, mother: Randgen.first_name },
          href: 'www.example.com',
          alive: true
        }
      end

      let(:resource) { blueprint_class.load(data).object }

      subject(:blueprint_instance) { blueprint_class.new(resource) }

      it_behaves_like 'a blueprint instance'

      context 'creating additional blueprint instances from that object' do
        subject(:additional_instance) { blueprint_class.new(resource) }

        context 'with caching enabled' do
          around do |example|
            Praxis::Blueprint.caching_enabled = true
            Praxis::Blueprint.cache = Hash.new { |h, k| h[k] = {} }
            example.run

            Praxis::Blueprint.caching_enabled = false
            Praxis::Blueprint.cache = nil
          end

          it 'uses the cache to memoize instance creation' do
            expect(additional_instance).to be(additional_instance)
            expect(blueprint_class.cache).to have_key(resource)
            expect(blueprint_class.cache[resource]).to be(blueprint_instance)
          end
        end

        context 'with caching disabled' do
          it { should_not be blueprint_instance }
        end
      end
    end
  end

  context '.validate' do
    let(:hash) { { name: 'bob' } }
    let(:person) { PersonBlueprint.load(hash) }
    subject(:errors) { person.validate }

    context 'that is valid' do
      it { should be_empty }
    end

    context 'with a valid nested blueprint' do
      let(:hash) { { name: 'bob', myself: { name: 'PseudoBob' } } }

      it { should be_empty }
    end

    context 'with invalid sub-attribute' do
      let(:hash) { { name: 'bob', address: { state: 'ME' } } }

      it { should have(1).item }
      its(:first) { should =~ /Attribute \$.address.state/ }
    end

    context 'with an invalid nested blueprint' do
      let(:hash) { { name: 'bob', myself: { name: 'PseudoBob', address: { state: 'ME' } } } }

      it { should have(1).item }
      its(:first) { should =~ /Attribute \$.myself.address.state/ }
    end

    context 'for objects of the wrong type' do
      it 'raises an error' do
        expect do
          PersonBlueprint.validate(Object.new)
        end.to raise_error(ArgumentError, /Error validating .* as PersonBlueprint for an object of type Object/)
      end
    end
  end

  context '.load' do
    let(:hash) do
      {
        name: 'Bob',
        full_name: { first: 'Robert', last: 'Robertson' },
        address: { street: 'main', state: 'OR' }
      }
    end
    subject(:person) { PersonBlueprint.load(hash) }

    it { should be_kind_of(PersonBlueprint) }

    context 'recursively loading sub-attributes' do
      context 'for a Blueprint' do
        subject(:address) { person.address }
        it { should be_kind_of(AddressBlueprint) }
      end
      context 'for an Attributor::Model' do
        subject(:full_name) { person.full_name }
        it { should be_kind_of(FullName) }
      end
    end
  end

  # TODO: Think about this 'feature' ...
  # context 'with a provided :reference option on attributes' do
  #   context 'that does not match the value set on the class' do
  #     subject(:mismatched_reference) do
  #       Class.new(Praxis::Blueprint) do
  #         self.reference = Class.new(Praxis::Blueprint)
  #         attributes(reference: Class.new(Praxis::Blueprint)) {}
  #       end
  #     end

  #     it 'should raise an error' do
  #       expect do
  #         mismatched_reference.attributes
  #       end.to raise_error(/Reference mismatch/)
  #     end
  #   end
  # end

  context '.example' do
    context 'with some attribute values provided' do
      let(:name) { 'Sir Bobbert' }
      subject(:person) { PersonBlueprint.example(name: name) }
      its(:name) { should eq(name) }
    end
  end

  context '.render' do
    let(:person) { PersonBlueprint.example('1') }
    it 'is an alias to dump' do
      person.object.contents
      rendered = PersonBlueprint.render(person, fields: %i[name full_name])
      dumped = PersonBlueprint.dump(person, fields: %i[name full_name])
      expect(rendered).to eq(dumped)
    end
  end

  context '#render' do
    let(:person) { PersonBlueprint.example }
    let(:fields) do
      {
        name: true,
        full_name: true,
        address: {
          street: true,
          state: true
        },
        prior_addresses: {
          street: true,
          state: true
        }
      }
    end
    let(:render_opts) { {} }
    subject(:output) { person.render(fields: fields, **render_opts) }

    context 'without passing fields' do
      it 'renders the default field set defined' do
        rendered = person.render(**render_opts)
        default_top_fields = PersonBlueprint.default_fieldset.keys
        expect(rendered.keys).to match_array(default_top_fields)
        expect(default_top_fields).to match_array(%i[
                                                    name
                                                    full_name
                                                    address
                                                    prior_addresses
                                                  ])
      end
    end
    context 'with a sub-attribute that is a blueprint' do
      it { should have_key(:name) }
      it { should have_key(:address) }
      it 'renders the sub-attribute correctly' do
        expect(output[:address]).to have_key(:street)
        expect(output[:address]).to have_key(:state)
      end

      it 'reports a dump error with the appropriate context' do
        expect(person.address).to receive(:state).and_raise('Kaboom')
        expect do
          person.render(fields: fields, context: ['special_root'])
        end.to raise_error(/Error while dumping attribute state of type AddressBlueprint for context special_root.address. Reason: .*Kaboom/)
      end
    end

    context 'with sub-attribute that is an Attributor::Model' do
      it { should have_key(:full_name) }
      it 'renders the model correctly' do
        expect(output[:full_name]).to be_kind_of(Hash)
        expect(output[:full_name]).to have_key(:first)
        expect(output[:full_name]).to have_key(:last)
      end
    end

    context 'using the `fields` option' do
      context 'as a hash' do
        subject(:output) { person.render(fields: { address: { state: true } }) }
        it 'should only have the address rendered' do
          expect(output.keys).to eq [:address]
        end
        it 'address should only have state' do
          expect(output[:address].keys).to eq [:state]
        end
      end
      context 'as a simple array' do
        subject(:output) { person.render(fields: [:full_name]) }
        it 'accepts it as the list of top-level attributes to be rendered' do
          expect(output.keys).to match_array([:full_name])
        end
      end
    end

    context 'using un-expanded fields for blueprints' do
      let(:fields) do
        {
          name: true,
          address: true # A blueprint!
        }
      end
      it 'should still render the blueprint sub-attribute with its default fieldset' do
        address_default_top_fieldset = AddressBlueprint.default_fieldset.keys
        expect(output[:address].keys).to match(address_default_top_fieldset)
      end
    end
  end

  context '.as_json_schema' do
    it 'delegates to the attribute type' do
      expect(PersonBlueprint.attribute.type).to receive(:as_json_schema)
      PersonBlueprint.as_json_schema
    end
  end
  context '.json_schema_type' do
    it 'delegates to the attribute type' do
      expect(PersonBlueprint.attribute.type).to receive(:json_schema_type)
      PersonBlueprint.json_schema_type
    end
  end

  context 'FieldsetParser' do
    let(:definition_block) do
      proc do
        attribute :one
        attribute :two do
          attribute :sub_two
        end
      end
    end
    subject { described_class::FieldsetParser.new(&definition_block) }

    it 'parses properly' do
      expect(subject.fieldset).to eq(one: true, two: { sub_two: true })
    end

    context 'with attribute parameters' do
      let(:definition_block) do
        proc do
          attribute :one, view: :other
        end
      end
      it 'complains and gives instructions if legacy view :default' do
        expect { subject.fieldset }.to raise_error(/Default fieldset definitions do not accept parameters/)
      end
    end
  end
end
