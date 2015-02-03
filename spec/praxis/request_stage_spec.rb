require 'spec_helper'

describe Praxis::RequestStages::RequestStage do

  #let(:before_controller_callback) { Proc.new { nil } }
  #let(:after_controller_callback) { Proc.new { nil } }

  #let(:before_show_controller_callback) { Proc.new { Praxis::Responses::Unauthorized.new } }

  let(:controller_class) do
    Class.new do
      include Praxis::Controller
    end
  end

  let(:stage_class) { Class.new(Praxis::RequestStages::RequestStage) }

  let(:request) { instance_double("Praxis::Request") }
  let(:controller){ controller_class.new(request) }

  let(:action_name) { :unknown }

  let(:action){ instance_double("Praxis::ActionDefinition", name: action_name) }
  let(:context){ double("context", controller: controller , action: action) }

  let(:substage_1) { instance_double('Praxis::RequestStage') }
  let(:substage_2) { instance_double('Praxis::RequestStage') }
  let(:substage_3) { instance_double('Praxis::RequestStage') }

  let(:before_callbacks) { double('before_callbacks') }
  let(:after_callbacks) { double('after_callbacks') }
  let(:controller_before_callbacks) { double('controller_before_callbacks') }
  let(:controller_after_callbacks) { double('controller_after_callbacks') }

  subject(:stage) { stage_class.new(:action, context) }


  before do
    # clear any pre-existing callbacks that may have been added by plugins
    controller_class.before_callbacks = Hash.new
    controller_class.after_callbacks = Hash.new

    #controller_class.before :action, &before_controller_callback
    #controller_class.after :action, &after_controller_callback
    #controller_class.before actions: [:show], &before_show_controller_callback
  end

  context 'for an abstract stage' do
    subject(:stage) { Praxis::RequestStages::RequestStage.new(:action, context) }
    it 'raises NotImplementedError for undefined #execute' do
      expect{stage.execute}.to raise_error(NotImplementedError,/Subclass must implement Stage#execute/)
    end
  end


  context ".run" do
    after do
      stage.run
    end

    let(:before_callbacks) { double('before_callbacks') }
    let(:after_callbacks) { double('after_callbacks') }

    let(:controller_before_callbacks) { double('controller_before_callbacks') }
    let(:controller_after_callbacks) { double('controller_after_callbacks') }

    context 'callback execution' do
      before do
        expect(stage).to receive(:before_callbacks).once.and_return(before_callbacks)
        expect(stage).to receive(:after_callbacks).once.and_return(after_callbacks)

        expect(controller_class).to receive(:before_callbacks).once.and_return(controller_before_callbacks)
        expect(controller_class).to receive(:after_callbacks).once.and_return(controller_after_callbacks)
      end

      it "sets up and executes callbacks" do
        expect(stage).to receive(:setup!)
        expect(stage).to receive(:setup_deferred_callbacks!)
        expect(stage).to receive(:execute)
        expect(stage).to receive(:execute_callbacks).once.with(before_callbacks)
        expect(stage).to receive(:execute_callbacks).once.with(after_callbacks)
        expect(stage).to receive(:execute_controller_callbacks).once.with(controller_before_callbacks)
        expect(stage).to receive(:execute_controller_callbacks).once.with(controller_after_callbacks)
      end

    end

    context 'when the before execute_controller_callbacks return a Response' do
      let(:action_name) { :show }

      before do
        expect(stage).to receive(:execute_controller_callbacks).once.and_return(Praxis::Responses::Unauthorized.new)
      end

      it 'does not call "execute"' do
        expect(stage).to_not receive(:execute)
      end

      it 'does not execute any "after" callbacks' do
        expect(stage).to_not receive(:after_callbacks)
        expect(controller_class).to_not receive(:after_callbacks)
      end
    end

    context 'with substages' do
      before do
        stage.stages.push(substage_1, substage_2, substage_3)
      end

      context 'when one returns a Response' do
        before do
          expect(substage_1).to receive(:run).once
          expect(substage_2).to receive(:run).once.and_return(Praxis::Responses::Ok.new)
        end

        it 'runs no after callbacks' do
          expect(stage).to_not receive(:after_callbacks)
          expect(controller_class).to_not receive(:after_callbacks)
        end
      end
    end
  end


  context ".execute" do
    before do
      stage.stages.push(substage_1, substage_2, substage_3)
    end

    context 'when all stages succeed' do
      it "runs them all and returns nil" do
        expect(substage_1).to receive(:run).once
        expect(substage_2).to receive(:run).once
        expect(substage_3).to receive(:run).once
        expect(stage.execute).to be(nil)
      end
    end

    context 'when one stage returns a Response' do
      before do
        expect(substage_1).to receive(:run).once
        expect(substage_2).to receive(:run).once.and_return(Praxis::Responses::Ok.new)
      end

      it "runs no further stages after that" do
        expect(substage_3).to_not receive(:run)
        stage.execute
      end
    end
  end
end
