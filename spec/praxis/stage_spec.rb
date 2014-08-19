require 'spec_helper'

describe Praxis::Stage do
  subject(:stage) {Praxis::Stage.new("name","context")}

  context "attributes" do
    its(:name) {should eq("name")}
    its(:context) {should eq("context")}
    its(:stages) {should eq([])}
    its(:before_callbacks) {should eq([])}
    its(:after_callbacks) {should eq([])}
  end

  context ".run" do
    it "sets up and execute callbacks" do
      expect(stage).to receive('setup!')
      expect(stage).to receive('setup_deferred_callbacks!')
      expect(stage).to receive('execute')
      expect(stage).to receive('execute_callbacks').twice
      stage.run
    end
  end

  context ".setup!" do
    it "should do something"
  end

  context ".setup_deferred_callbacks!" do
    it "calls .before and .after for each stage name in @deferred_callbacks" do
      deferred_callbacks = {
        "stage" => {
          :before => [["before",nil]],
          :after  => [["after",nil]]
        }}
      stage.instance_variable_set("@deferred_callbacks", deferred_callbacks)
      expect(stage).to receive("before")
      expect(stage).to receive("after")
      stage.setup_deferred_callbacks!
    end
  end

  context ".execute" do
    it "raises error when @stages is empty" do
      error_msg = 'Subclass must implement Stage#execute'
      expect{stage.execute}.to raise_error(NotImplementedError, error_msg)
    end

    it "runs all the stages" do
      double_stage = double("stage")
      expect(double_stage).to receive('run')
      stage.instance_variable_set("@stages", [double_stage])
      stage.execute
    end
  end

  context ".execute_callbacks" do
    let(:callback) {double('callback')}
    it "executes every callback" do
      expect(callback).to receive("call")
      stage.execute_callbacks([callback])
    end
  end

  context ".callback_args" do
    # TODO should this method return something else than nil?
    it "returns nil" do
      expect(stage.callback_args).to be(nil)
    end
  end

  context ".before" do
    it "adds block to @before_callbacks when stage_path is not provided" do
      stage.before {1}
      expect(stage.before_callbacks.last.call).to be(1)
    end

    it "calls .before for the name matched stage" do
      double_stage = double("stage", name: "name")
      expect(double_stage).to receive('before')
      stage.instance_variable_set("@stages", [double_stage])
      stage.before("name")
    end

    it "adds to deferred_callbacks if no state name matched" do
      double_stage = double("stage", name: "name")
      stage.instance_variable_set("@stages", [double_stage])
      expect(stage.before("hello", "world")).to eq([["world",nil]])
    end
  end

  context ".after" do
    it "adds block to @after_callbacks when stage_path is not provided" do
      stage.after {1}
      expect(stage.after_callbacks.last.call).to be(1)
    end

    it "calls .after for the name matched stage" do
      double_stage = double("stage", name: "name")
      expect(double_stage).to receive("after")
      stage.instance_variable_set("@stages", [double_stage])
      stage.after("name")
    end

    it "adds to deferred_callbacks if no state name matched" do
      double_stage = double("stage", name: "name")
      stage.instance_variable_set("@stages", [double_stage])
      expect(stage.after("hello", "world")).to eq([["world",nil]])
    end
  end
end
