require "spec_helper"

describe Praxis::MediaTypeCollection do

  let(:type) { Volume }
  let(:example) { Volume.example('example-volume') }

  let(:snapshots) { example.snapshots }

  subject(:media_type_collection) do
    Class.new(Praxis::MediaTypeCollection) do
      member_type Volume
    end
  end
   
  context '.member_type' do
    its(:member_type){ should be(Volume) }
    its(:member_attribute){ should be_kind_of(Attributor::Attribute) }
    its('member_attribute.type'){ should be(Volume) }
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

    context 'with a hash' do
      let(:snapshots_data) { {name: 'snapshots',   href: '/bob/snapshots' } }

      let(:volume) { Volume.load(volume_data) }
      subject(:snapshots) { volume.snapshots }

      its(:name) { should eq(snapshots_data[:name]) }
      its(:href) { should eq(snapshots_data[:href]) }

      it 'has no members set' do
        expect(snapshots.to_a).to eq([])
      end
    end


    context 'loading an array' do
      let(:snapshots_data) do
        [{id: 1, name: 'snapshot-1'},
         {id: 2, name: 'snapshot-2'}]
      end

      let(:volume) { Volume.load(volume_data) }
      let(:snapshots) { volume.snapshots }
      subject(:members) { snapshots.to_a }

      it 'sets the collection members' do
        expect(members).to have(2).items

        expect(members[0].id).to eq(1)
        expect(members[0].name).to eq('snapshot-1')
        expect(members[1].id).to eq(2)
        expect(members[1].name).to eq('snapshot-2')
      end

      it 'has no attributes set' do
        expect(snapshots.name).to be(nil)
        expect(snapshots.size).to be(nil)
        expect(snapshots.href).to be(nil)
      end

    end
  end


  context '#render' do

    context 'for standard views' do
      subject(:output) { snapshots.render(:link) }

      its([:name]) { should eq(snapshots.name)}
      its([:size]) { should eq(snapshots.size)}
      its([:href]) { should eq(snapshots.href)}
    end

    context 'for member views' do
      subject(:output) { snapshots.render(:default) }

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

    context 'with a hash' do
      let(:snapshots_data) { {name: 'snapshots-1',   href: '/bob/snapshots' } }

      let(:volume) { Volume.load(volume_data) }
      subject(:snapshots) { volume.snapshots }

      it 'validates' do
        expect(snapshots.validate).to be_empty
      end

      context 'with invalid attributes' do
        let(:snapshots_data) { {name: 'notsnapshots',   href: '/bob/snapshots' } }
        it 'returns the error' do
          expect(snapshots.validate).to have(1).item
          expect(snapshots.validate[0]).to match(/value \(notsnapshots\) does not match regexp/)
        end
      end
    end

    context 'for an array' do
      let(:snapshots_data) do
        [{id: 1, name: 'snapshot-1'},
         {id: 2, name: 'snapshot-2'}]
      end

      let(:volume) { Volume.load(volume_data) }
      let(:snapshots) { volume.snapshots }
      subject(:members) { snapshots.to_a }
      
      it 'validates' do
        expect(snapshots.validate).to be_empty
      end

      context 'with invalid members' do
        let(:snapshots_data) do
          [{id: 1, name: 'invalid-1'},
           {id: 2, name: 'snapshot-2'}]
        end

        it 'returns the error' do
          expect(snapshots.validate).to have(1).item
          expect(snapshots.validate[0]).to match(/value \(invalid-1\) does not match regexp/)
        end
      end
    end
  end

end
