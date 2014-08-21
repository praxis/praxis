require "spec_helper"

describe Praxis::MediaTypeCollection do

  let(:type) { Volume }
  let(:example) { Volume.example('example-volume') }

  let(:snapshots) { example.snapshots }

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

    context 'for views that are not defined on on the collection' do
      subject(:output) { snapshots.render(:default) }

      it { should eq(snapshots.collect(&:render)) }
    end

    context 'for defined views' do
      subject(:output) { snapshots.render(:link) }

      its([:name]) { should eq(snapshots.name)}
      its([:size]) { should eq(snapshots.size)}
      its([:href]) { should eq(snapshots.href)}
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
      let(:snapshots_data) { {name: 'snapshots',   href: '/bob/snapshots' } }

      let(:volume) { Volume.load(volume_data) }
      subject(:snapshots) { volume.snapshots }

      it 'validates' do
        p snapshots.validate
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
        p snapshots.validate
      end

    end
  end

end
