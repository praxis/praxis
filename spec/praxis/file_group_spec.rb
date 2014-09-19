require 'spec_helper'

describe Praxis::FileGroup do
  let(:app) { Praxis::Application.instance }
  let(:layout) { app.file_layout }

  context '#initialize' do 
    it 'raises an error if given nil for the base path' do
      expect { Praxis::FileGroup.new(nil) }.to raise_error(ArgumentError)
    end
  end
  context '#base' do
    it 'returns the base path for the group' do
      expect(layout[:design].base.to_s).to eq(File.join(app.root, 'design/'))
    end
  end

  context '#groups' do
    subject(:groups) { layout.groups }

    it 'returns a hash' do
      expect(groups).to be_kind_of(Hash)
    end

    it 'shows the files mapped to groups' do
      expect(groups).to have_key(:app)
      expect(groups).to have_key(:design)
      expect(groups[:app]).to be_kind_of(described_class)
    end
  end

  context '#[]' do
    it 'returns files in a specific group' do
      expect(layout[:app]).to eq(layout.groups[:app])
      expect(layout[:design]).to be_kind_of(described_class)
      expect(layout[:design][:media_types]).to eq(layout.groups[:design].groups[:media_types])
    end
  end
end
