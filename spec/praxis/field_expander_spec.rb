# frozen_string_literal: true

require 'spec_helper'

describe Praxis::FieldExpander do
  let(:field_expander) { Praxis::FieldExpander.new }
  let(:expanded_person_default_fieldset) do
    # The only ones that are not already leaves is the full name, which can expand to first, last
    PersonBlueprint.default_fieldset.merge!(full_name: { first: true, last: true })
  end
  let(:expanded_address_default_fieldset) do
    # AddressBlueprint' default fieldset already has all attributes as leaves
    AddressBlueprint.default_fieldset
  end

  context '.expand' do
    let(:display_attribute_filter) { ->(required) { (required & allowed) == required } }
    let(:all_fields) { { id: true, secret_data: true, pii_data: true } }
    subject { described_class.expand(object_type, all_fields, display_attribute_filter) }
    context 'with a displayable attribute at the top' do
      let(:object_type) { RestrictedBlueprint }
      context 'when it has the right permissions for the top and inner ones' do
        let(:allowed) { ['restricted#read', 'pii#read'] }
        it 'calls the underlying expander instance (i.e., expands it all)' do
          expect(subject).to eq(id: true, secret_data: true, pii_data: true)
        end
      end
      context 'when it has the right permissions for the top, but not the inner' do
        let(:allowed) { ['restricted#read'] }
        it 'calls the underlying expander instance (i.e., expands it all)' do
          expect(subject).to eq(id: true, secret_data: true)
        end
      end
      context 'when it does NOT have the right permissions on the top' do
        let(:allowed) { ['pii#read'] } # Yet it would have the inner one
        it 'directly returns empty hash (i.e., nothing is expanded)' do
          expect(subject).to eq({})
        end
      end
    end

    context 'with type that has an attribute that points to another type with a displayable attribute at the top' do
      let(:object_type) { PseudoRestrictedBlueprint }
      let(:all_fields) { { id: true, restricted: true } }
      context 'when it has the right permissions for the top of the inner one' do
        let(:allowed) { ['restricted#read'] }
        it 'calls the underlying expander instance including the inner type' do
          expect(subject).to eq(id: true, restricted: { id: true, secret_data: true })
          expect(subject[:restricted].keys).to_not include(:pii_data)
        end
      end
      context 'when it does NOT have the right permissions for the top of the inner one' do
        let(:allowed) { ['another#read'] }
        it 'does not expand it' do
          expect(subject).to eq(id: true)
          expect(subject.keys).to_not include(:restricted)
        end
      end
    end
  end

  context 'expanding attributes of a PersonBlueprint blueprint' do
    it 'with fields=true, expands all fields on the default fieldset' do
      expect(field_expander.expand(PersonBlueprint, true)).to eq(expanded_person_default_fieldset)
    end

    it 'expands for a subset of the direct fields' do
      expect(field_expander.expand(PersonBlueprint, name: true)).to eq(name: true)
    end

    it 'raises when trying to expand fields that do not exist in the type' do
      expect do
        field_expander.expand(PersonBlueprint, name: true, foobar: true)
      end.to raise_error(/.*:foobar.*do not exist in PersonBlueprint/)
    end

    context 'given inlined struct attribtue' do
      it 'expands for a sub-struct' do
        expect(field_expander.expand(PersonBlueprint, parents: true)).to eq(parents: { mother: true, father: true })
      end

      it 'expands for a subset of a substruct' do
        expect(field_expander.expand(PersonBlueprint, parents: { mother: true })).to eq(parents: { mother: true })
      end
    end

    context 'given a non-inlined struct sub attribute' do
      it 'expands a specific subattribute of a struct' do
        expect(field_expander.expand(PersonBlueprint, full_name: { first: true })).to eq(full_name: { first: true })
      end

      it 'fully expands collections properly by simply listing subfields' do
        expect(field_expander.expand(PersonBlueprint, prior_addresses: true)).to eq(prior_addresses: expanded_address_default_fieldset)
      end
    end

    context 'given a attribute that is also a blueprint' do
      it 'expands to default fieldset for an attribute that is also blueprint' do
        expect(field_expander.expand(PersonBlueprint, address: true)).to eq(address: expanded_address_default_fieldset)
      end

      it 'expands to default fieldset for a subset of fields of an attribute that is a blueprint' do
        expect(field_expander.expand(PersonBlueprint, address: { resident: true })).to eq(address: { resident: expanded_person_default_fieldset })
      end
    end

    context 'collection attributes' do
      it 'expands subfields by simply listing subfields the same as structs/blueprints' do
        expect(field_expander.expand(PersonBlueprint, prior_addresses: { state: true })).to eq(prior_addresses: { state: true })
      end
    end
  end

  it 'expands for for a primitive type' do
    expect(field_expander.expand(String)).to eq(true)
  end

  it 'expands for an Attributor::Model' do
    expect(field_expander.expand(FullName)).to eq(first: true, last: true)
  end

  it 'expands for a Blueprint' do
    expect(field_expander.expand(PersonBlueprint, parents: true)).to eq(parents: { father: true, mother: true })
  end

  it 'expands for an Attributor::Collection of an Attrbutor::Model' do
    expect(field_expander.expand(Attributor::Collection.of(FullName))).to eq(first: true, last: true)
  end

  it 'expands for an Attributor::Collection of a Blueprint' do
    expected = { name: true, resident: { full_name: { first: true, last: true } } }
    expect(field_expander.expand(Attributor::Collection.of(AddressBlueprint), name: true, resident: { full_name: true })).to eq(expected)
  end

  it 'also expands array-wrapped field hashes for collections' do
    expected = { name: true, resident: { full_name: { first: true, last: true } } }
    expect(field_expander.expand(Attributor::Collection.of(AddressBlueprint), name: true, resident: { full_name: true })).to eq(expected)
  end

  it 'expands for an Attributor::Collection of a primitive type' do
    expect(field_expander.expand(Attributor::Collection.of(String))).to eq(true)
  end

  context 'expanding a two-dimensional collection' do
    it 'expands the fields discarding the collection nexting nesting' do
      matrix_type = Attributor::Collection.of(Attributor::Collection.of(FullName))
      expect(field_expander.expand(matrix_type)).to eq(first: true, last: true)
    end
  end

  context 'circular expansions' do
    it 'preserve field object identity for circular references' do
      result = field_expander.expand(PersonBlueprint, address: { resident: true }, work_address: { resident: true })
      expect(result[:address][:resident]).to be(result[:work_address][:resident])
    end

    context 'with collections of Blueprints' do
      it 'still preserves object identity' do
        result = field_expander.expand(PersonBlueprint, address: { resident: true }, prior_addresses: { resident: true })
        expect(result[:address][:resident]).to be(result[:prior_addresses][:resident])
      end
    end
  end

  it 'optimizes duplicate field expansions' do
    expect(field_expander.expand(FullName, true)).to be(field_expander.expand(FullName, true))
  end

  context 'expanding hash attributes' do
    let(:type) do
      Class.new(Attributor::Model) do
        attributes do
          attribute :name, String
          attribute :simple_hash, Hash
          attribute :keyed_hash, Hash do
            key :foo, String
            key :bar, String
          end
          attribute :some_struct do
            attribute :something, String
          end
        end
      end
    end

    it 'expands' do
      expected = {
        name: true,
        simple_hash: true,
        keyed_hash: { foo: true, bar: true },
        some_struct: { something: true }
      }
      expect(field_expander.expand(type, true)).to eq(expected)
    end
  end
end
