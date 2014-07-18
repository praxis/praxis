require 'spec_helper'

describe Praxis::FileGroup do
  subject(:app_config) do
    Praxis::Application.configure do |app|
      app.layout do
        layout do
          map :spec, 'spec/*'
          map :support, 'spec/support' do
            map :files, '*'
          end
        end
      end
    end
  end

  context '#base' do
    it 'returns the base path for the group' do
      expect(app_config[:support].base.to_s).to eq(File.join(app_config.base, 'spec/support'))
    end
  end

  context '#groups' do
    subject(:groups) { app_config.groups }

    it 'returns a hash' do
      binding.pry
      expect(groups).to be_kind_of(Hash)
    end

    it 'shows the files mapped to groups' do
      expect(groups).to have_key(:spec)
      expect(groups).to have_key(:support)
      expect(groups[:support]).to be_kind_of(described_class)
    end
  end

  context '#[]' do
    it 'returns files in a specific group' do
      expect(app_config[:spec]).to eq(app_config.groups[:spec])
      expect(app_config[:support]).to be_kind_of(described_class)
      expect(app_config[:support][:files]).to eq(app_config.groups[:support].groups[:files])
    end
  end
end
