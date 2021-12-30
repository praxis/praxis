# frozen_string_literal: true

require 'spec_helper'

describe Praxis::Collection do
  let(:member_type) { Volume }

  subject!(:collection) do
    Praxis::Collection.of(member_type)
  end
  let(:identifier_string) { subject.identifier.to_s }

  context '.of' do
    let(:member_type) do
      Class.new(Praxis::MediaType) do
        identifier 'application/an-awesome-type'
      end
    end

    it { expect(identifier_string).to eq('application/an-awesome-type; type=collection') }

    it 'sets the collection on the media type' do
      expect(member_type::Collection).to be(collection)
    end

    it 'returns an existing Collection type' do
      expect(Praxis::Collection.of(member_type)).to be(collection)
    end

    it 'works with explicitly-defined collections' do
      expect(Praxis::Collection.of(Volume)).to be(Volume::Collection)
    end
  end

  context 'defined explicitly' do
    subject(:type) { Volume::Collection }
    its(:member_type) { should be Volume }
    it { expect(identifier_string).to eq('application/vnd.acme.volumes') }
  end

  context '.member_type' do
    subject(:collection) do
      Class.new(Praxis::Collection) do
        member_type Person
      end
    end
    its(:member_type) { should be(Person) }
    its(:member_attribute) { should be_kind_of(Attributor::Attribute) }
    its('member_attribute.type') { should be(Person) }
    its(:identifier) { should eq Person.identifier + '; type=collection' } # rubocop:disable Style/StringConcatenation
  end

  context '.load' do
    let(:volume_data) do
      {
        id: 1,
        name: 'bob',
        snapshots: snapshots_data
      }
    end

    let(:snapshots_data) do
      nil
    end

    context 'loading an array' do
      let(:snapshots_data) do
        [{ id: 1, name: 'snapshot-1' },
         { id: 2, name: 'snapshot-2' }]
      end

      let(:volume) { Volume.load(volume_data) }
      subject(:snapshots) { volume.snapshots }

      it 'sets the collection members' do
        expect(snapshots).to have(2).items

        expect(snapshots[0].id).to eq(1)
        expect(snapshots[0].name).to eq('snapshot-1')
        expect(snapshots[1].id).to eq(2)
        expect(snapshots[1].name).to eq('snapshot-2')
      end
    end
  end

  context '#render' do
    context 'for members' do
      let(:example) { Volume.example('example-volume') }
      let(:snapshots) { example.snapshots }

      let(:volume_output) { example.render(view: :default) }

      subject(:output) { volume_output[:snapshots] }

      it { should eq(snapshots.collect(&:render)) }
    end
  end

  context '#validate' do
    let(:volume_data) do
      {
        id: 1,
        name: 'bob',
        snapshots: snapshots_data
      }
    end

    let(:snapshots_data) do
      nil
    end

    context 'for an array' do
      let(:snapshots_data) do
        [{ id: 1, name: 'snapshot-1' },
         { id: 2, name: 'snapshot-2' }]
      end

      let(:volume) { Volume.load(volume_data) }
      let(:snapshots) { volume.snapshots }

      it 'validates' do
        expect(volume.validate).to be_empty
      end

      context 'with invalid members' do
        let(:snapshots_data) do
          [{ id: 1, name: 'invalid-1' },
           { id: 2, name: 'snapshot-2' }]
        end

        it 'returns the error' do
          expect(volume.validate).to have(1).item
          expect(volume.validate[0]).to match(/value \(invalid-1\) does not match regexp/)
        end
      end
    end
  end
end
