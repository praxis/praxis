require "spec_helper"

describe Praxis::MediaTypeCollection do

  subject!(:media_type_collection) do
    silence_warnings do
      klass = Class.new(Praxis::MediaTypeCollection) do
        member_type VolumeSnapshot
        description 'A container for a collection of Volumes'
        display_name 'Volumes Collection'

        attributes do
          attribute :name, String, regexp: /snapshots-(\w+)/
          attribute :size, Integer
          attribute :href, String
        end

        view :link do
          attribute :name
          attribute :size
          attribute :href
        end

        member_view :default, using: :default
      end

      klass.finalize!
      klass
    end
  end

  context '.member_type' do
    its(:member_type){ should be(VolumeSnapshot) }
    its(:member_attribute){ should be_kind_of(Attributor::Attribute) }
    its('member_attribute.type'){ should be(VolumeSnapshot) }
  end

  context '.load' do
    context 'with a hash' do
      let(:snapshots_data) { {name: 'snapshots',   href: '/bob/snapshots' } }
      subject(:snapshots) { media_type_collection.load(snapshots_data) }

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

      let(:snapshots) { media_type_collection.load(snapshots_data) }
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
      let(:snapshots_data) { {name: 'snapshots',   href: '/bob/snapshots' } }
      let(:snapshots) { media_type_collection.load(snapshots_data) }
      subject(:output) { snapshots.render(view: :link) }

      its([:name]) { should eq(snapshots.name)}
      its([:size]) { should eq(snapshots.size)}
      its([:href]) { should eq(snapshots.href)}
    end

    context 'for members' do
      let(:snapshots_data) do
        [{id: 1, name: 'snapshot-1'},
         {id: 2, name: 'snapshot-2'}]
      end

      let(:snapshots) { media_type_collection.load(snapshots_data) }

      subject(:output) { media_type_collection.dump(snapshots, view: :default) }

      it { should eq(snapshots.collect(&:render)) }
    end

  end

  context '#validate' do


    context 'with a hash' do
      let(:snapshots_data) { {name: 'snapshots-1',   href: '/bob/snapshots' } }
      subject(:snapshots) { media_type_collection.load(snapshots_data) }


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

      subject(:snapshots) { media_type_collection.load(snapshots_data) }

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

  context '#describe' do
    subject(:described) { media_type_collection.describe }
    its([:description]){ should be(media_type_collection.description)}
    its([:display_name]){ should be(media_type_collection.display_name)}
  end
end
