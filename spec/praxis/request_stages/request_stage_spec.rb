# frozen_string_literal: true

require 'spec_helper'

describe Praxis::RequestStages::RequestStage do
  let(:controller_class) do
    Class.new do
      include Praxis::Controller
    end
  end

  let(:stage_class) { Class.new(Praxis::RequestStages::RequestStage) }

  let(:request) { Praxis::Request.new({}) }
  let(:controller) { controller_class.new(request) }

  let(:action) { instance_double('Praxis::ActionDefinition') }
  let(:context) { double('context', controller: controller, action: action) }

  let(:substage1) { instance_double('Praxis::RequestStage') }
  let(:substage2) { instance_double('Praxis::RequestStage') }
  let(:substage3) { instance_double('Praxis::RequestStage') }

  let(:before_callbacks) { double('before_callbacks') }
  let(:after_callbacks) { double('after_callbacks') }
  let(:controller_before_callbacks) { double('controller_before_callbacks') }
  let(:controller_after_callbacks) { double('controller_after_callbacks') }

  subject(:stage) { stage_class.new(:action, context) }

  before do
    # clear any pre-existing callbacks that may have been added by plugins
    controller_class.before_callbacks = ({})
    controller_class.after_callbacks = ({})
  end

  context 'for an abstract stage' do
    subject(:stage) { Praxis::RequestStages::RequestStage.new(:action, context) }
    it 'raises NotImplementedError for undefined #execute' do
      expect do
        stage.execute
      end.to raise_error(NotImplementedError, /Subclass must implement Stage#execute/)
    end
  end

  context 'execute_controller_callbacks' do
  end

  context 'execute_with_around' do
  end

  context '#setup!' do
    it 'sets up the deferred callbacks' do
      expect(stage).to receive(:setup_deferred_callbacks!).once
      stage.setup!
    end
  end

  context '#execute' do
    before do
      stage.stages.push(substage1, substage2, substage3)
    end

    context 'when all stages succeed' do
      it 'runs them all and returns nil' do
        expect(substage1).to receive(:run).once
        expect(substage2).to receive(:run).once
        expect(substage3).to receive(:run).once
        expect(stage.execute).to be(nil)
      end
    end

    context 'when one stage returns a Response' do
      let(:response) { Praxis::Responses::Ok.new }
      before do
        expect(substage1).to receive(:run).once
        expect(substage2).to receive(:run).once.and_return(response)
      end

      it 'runs no further stages after that' do
        expect(substage3).to_not receive(:run)
        stage.execute
      end

      it 'assigns the response to controller.response' do
        stage.execute

        expect(controller.response).to be(response)
      end
    end
  end

  context '#run' do
    let(:before_callbacks) { double('before_callbacks') }
    let(:after_callbacks) { double('after_callbacks') }

    let(:controller_before_callbacks) { double('controller_before_callbacks') }
    let(:controller_after_callbacks) { double('controller_after_callbacks') }

    after do
      stage.run
    end

    context 'callback execution' do
      before do
        allow(stage).to receive(:before_callbacks).once.and_return(before_callbacks)
        allow(stage).to receive(:after_callbacks).once.and_return(after_callbacks)

        allow(controller_class).to receive(:before_callbacks).once.and_return(controller_before_callbacks)
        allow(controller_class).to receive(:after_callbacks).once.and_return(controller_after_callbacks)
      end

      it 'sets up and executes callbacks' do
        expect(stage).to receive(:execute)
        expect(stage).to receive(:execute_callbacks).once.with(before_callbacks)
        expect(stage).to receive(:execute_callbacks).once.with(after_callbacks)
        expect(stage).to receive(:execute_controller_callbacks).once.with(controller_before_callbacks)
        expect(stage).to receive(:execute_controller_callbacks).once.with(controller_after_callbacks)
      end
    end

    context 'when the before execute_controller_callbacks return a Response' do
      let(:action_name) { :show }
      let(:response) { Praxis::Responses::Unauthorized.new }

      before do
        expect(stage).to receive(:execute_controller_callbacks).once.and_return(response)
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
        stage.stages.push(substage1, substage2, substage3)
      end

      context 'when one returns a Response' do
        let(:response) { Praxis::Responses::Unauthorized.new }

        before do
          expect(substage1).to receive(:run).once
          expect(substage2).to receive(:run).once.and_return(response)
          expect(substage3).to_not receive(:run)
        end

        it 'runs no after callbacks (including from the controller) ' do
          expect(stage).to_not receive(:after_callbacks)
          expect(controller_class).to_not receive(:after_callbacks)
        end

        it 'assigns controller.response' do
          # twice, because we do it once in #execute, and again in #run...
          expect(controller).to receive(:response=)
            .with(response).twice.and_call_original
        end
      end
    end
  end
end
