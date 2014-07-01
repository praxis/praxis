require 'spec_helper'

describe Praxis::MediaType do
  let(:media_type) { Instance }

  context '.example' do
    subject(:example) { media_type.example }

    its('links.root_volume') { should be(example.root_volume) }
    its('links.other_volume') { should be_kind_of(Volume) }
    it 'does not respond to non-top-level attributes from links' do
      expect { example.other_volume }.to raise_error(NoMethodError)
    end
    it 'responds to non-top-level attributes from links on its inner Struct' do
      expect(example.object.other_volume).to be(example.links.other_volume)
    end
  end

  context "rendering" do
    let(:example) { media_type.example }
    subject(:output) { example.render }

    its([:id]) { should eq(example.id) }
    its([:root_volume]) { should eq(example.root_volume.render) }

    context 'links' do
      subject(:links) { output[:links] }

      it { should have_key(:root_volume) }
      it { should have_key(:other_volume) }

      its([:root_volume]) { should eq(example.root_volume.render(:link))}
    end
  end


  context 'stuff loads magically... sure?' do
    let(:example) { media_type.example }
    let(:output) { example.render }

    it 'works' do
      #thing = media_type.load(output)
      #pp thing.render
      #expect(thing.root_volume).to be(thing.links.root_volume)
      #expect(thing.object.root_volume).to_not be(thing.object.links.root_volume)
    end

  end
end
