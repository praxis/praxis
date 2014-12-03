require 'spec_helper'

describe Praxis::Bootloader do
  let(:application) do
    instance_double("Praxis::Application", config: "config", root: "root", plugins: {})
  end

  subject(:bootloader) {Praxis::Bootloader.new(application)}

  context 'attributes' do
    its(:application) {should be(application)}
    it 'stages' do
      init_stages = [:environment, :plugins, :initializers, :lib, :design, :app, :routing, :warn_unloaded_files]
      expect(bootloader.stages.map {|s| s.name}).to eq(init_stages)
    end
    its(:config) {should be(application.config)}
    its(:root) {should be(application.root)}
  end

  context ".delete_stage" do
    it "delete valid stage" do
      bootloader.delete_stage(:app)
      expect(bootloader.stages.include?(:app)).to be(false)
    end

    it "raise errors when deleting invalid stage" do
      expect{bootloader.delete_stage(:unexistent_stage)}.to raise_error(Praxis::Exceptions::StageNotFound)
    end
  end

  context ".before" do
    it "run before block of first element in stage_path" do
      stage = bootloader.stages.first
      allow(stage).to receive(:before).and_return('before!')
      expect(bootloader.before(stage.name)).to eq('before!')
    end

    it "raises when given an invalid stage name"
  end

  context ".after" do
    it "run before block of first element in stage_path" do
      stage = bootloader.stages.first
      allow(stage).to receive(:after).and_return('after!')
      expect(bootloader.after(stage.name)).to eq('after!')
    end

    it "raises when given an invalid stage name"
  end

  context ".use" do
    let(:plugin) do
      Class.new(Praxis::Plugin) do
        def config_key
          :foo
        end
      end
    end

    it "plugin add to application" do
      bootloader.use(plugin)
      expect(bootloader.application.plugins[:foo].class).to be(plugin)
    end
  end
end
