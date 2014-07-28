require 'spec_helper'

describe Praxis::Bootloader do
  let(:application) do
    double("application", config: "config", root: "root", plugins: [])
  end

  subject(:bootloader) {Praxis::Bootloader.new(application)}

  context 'attributes' do
    its(:application) {should be(application)}
    it 'stages' do
      init_stages = [:environment, :initializers, :app, :routing, :warn_unloaded_files]
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
      error_message = "Can not remove stage with name go_right_scale, stage does not exist."
      expect{bootloader.delete_stage(:go_right_scale)}.to raise_error(RuntimeError,error_message)
    end
  end

  context ".before" do
    it "run before block of first element in stage_path" do
      stage = bootloader.stages.first
      stage.stub('before').and_return('before!')
      expect(bootloader.before(stage.name)).to eq('before!')
    end

    it "raises when given an invalid stage name"
  end

  context ".after" do
    it "run before block of first element in stage_path" do
      stage = bootloader.stages.first
      stage.stub('after').and_return('after!')
      expect(bootloader.after(stage.name)).to eq('after!')
    end

    it "raises when given an invalid stage name"
  end

  context ".use" do
    it "plugin add to application" do
      bootloader.use(Praxis::Plugin)
      new_plugin = Praxis::Plugin.new(bootloader.application)
      expect(bootloader.application.plugins.last.class).to be(Praxis::Plugin)
    end
  end
end
