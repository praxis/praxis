require "spec_helper"

describe Praxis::Collection do

  let(:type) { Volume }
  let(:example) { Volume.example('example-volume') }

  let(:snapshots) { example.snapshots }

  subject(:media_type_collection) do
    Volume.attributes[:snapshots].type
  end

  context '.of' do
    let(:media_type) do
      Class.new(Praxis::MediaType) do
        identifier 'application/an-awesome-type'
      end
    end

    subject!(:collection) do
      Praxis::Collection.of(media_type)
    end

    its(:identifier) { should eq Praxis::MediaTypeIdentifier.load('application/an-awesome-type;type=collection') }

    it 'sets the collection on the media type' do
      expect(media_type::Collection).to be(collection)
    end

    it 'returns an existing Collection type' do
      expect(Praxis::Collection.of(media_type)).to be(collection)
    end

    it 'works with explicitly-defined collections' do
      expect(Praxis::Collection.of(Volume)).to be(Volume::Collection)
    end
  end

  context 'defined explicitly' do
    subject(:type) { Volume::Collection }
    its(:member_type) { should be Volume }
    its(:identifier) { should eq Praxis::MediaTypeIdentifier.load('application/vnd.acme.volumes') }

  end

  context '.member_type' do
    its(:member_type){ should be(VolumeSnapshot) }
    its(:member_attribute){ should be_kind_of(Attributor::Attribute) }
    its('member_attribute.type'){ should be(VolumeSnapshot) }
  end
  
  context '.load' do
    let(:volume_data) do
      {
        id: 1,
        name: 'bob',
        snapshots: snapshots_data
      }
    end

    let(:snapshots_data) {
      nil
    }


    context 'loading an array' do
      let(:snapshots_data) do
        [{id: 1, name: 'snapshot-1'},
         {id: 2, name: 'snapshot-2'}]
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
      let(:volume_output) { example.render(:default) }

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

    let(:snapshots_data) {
      nil
    }


    context 'for an array' do
      let(:snapshots_data) do
        [{id: 1, name: 'snapshot-1'},
         {id: 2, name: 'snapshot-2'}]
      end

      let(:volume) { Volume.load(volume_data) }
      let(:snapshots) { volume.snapshots }
      
      it 'validates' do
        expect(volume.validate).to be_empty
      end

      context 'with invalid members' do
        let(:snapshots_data) do
          [{id: 1, name: 'invalid-1'},
           {id: 2, name: 'snapshot-2'}]
        end

        it 'returns the error' do
          expect(volume.validate).to have(1).item
          expect(volume.validate[0]).to match(/value \(invalid-1\) does not match regexp/)
        end
      end
    end
  end

end
