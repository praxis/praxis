# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

describe Praxis::Blueprint do
  subject(:blueprint_class) { PersonBlueprint }

  its(:family) { should eq('hash') }

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
    expect(blueprint_class.attribute.type).to be blueprint_class::Struct
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
      let(:hash) { { name: 'bob', myself: { name: 'PseudoBob'}} }

      it { should be_empty }
    end

    context 'with invalid sub-attribute' do
      let(:hash) { { name: 'bob', address: { state: 'ME' } } }

      it { should have(1).item }
      its(:first) { should =~ /Attribute \$.address.state/ }
    end

    context 'with an invalid nested blueprint' do
      let(:hash) { { name: 'bob', myself: { name: 'PseudoBob', address: { state: 'ME' }}} }

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

  context 'with a provided :reference option on attributes' do
    context 'that does not match the value set on the class' do
      subject(:mismatched_reference) do
        Class.new(Praxis::Blueprint) do
          self.reference = Class.new(Praxis::Blueprint)
          attributes(reference: Class.new(Praxis::Blueprint)) {}
        end
      end

      it 'should raise an error' do
        expect do
          mismatched_reference.attributes
        end.to raise_error(/Reference mismatch/)
      end
    end
  end

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
