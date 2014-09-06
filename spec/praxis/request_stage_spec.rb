require 'spec_helper'

describe Praxis::RequestStages::RequestStage do
  # Ugly, but clear and easy to test the shortcuts
  $before_controller_callback = Proc.new { nil }
  $after_controller_callback = Proc.new { nil }
  $before_show_controller_callback = Proc.new { Praxis::Responses::Unauthorized.new }

  class MyController
    include Praxis::Controller
    before( :action , &$before_controller_callback) 
    after( :action , &$after_controller_callback) 
    before( actions: [:show], &$before_show_controller_callback) 
  end
  class MyStage < Praxis::RequestStages::RequestStage
  end
  
  let(:controller){ MyController.new( double("request") ) }
  let(:action_name) { :unknown }
  let(:action){ double("action", name: action_name )}
  let(:context){ double("context", controller: controller , action: action )}
  subject(:stage) { MyStage.new(:action, context) }

  context ".run" do
    context 'for an abstract stage' do
      subject(:stage) {Praxis::RequestStages::RequestStage.new(:action, context)}
      it 'complains about having to implement execute' do
        expect{stage.run}.to raise_error(NotImplementedError,/Subclass must implement Stage#execute/)
      end
    end
    
    it "sets up and execute callbacks" do
      expect(stage).to receive(:setup!)
      expect(stage).to receive(:setup_deferred_callbacks!)
      expect(stage).to receive(:execute)
      expect(stage).to receive(:execute_callbacks).twice
      expect(stage).to receive(:execute_controller_callbacks).twice
      stage.run
    end
        
    
    context 'when before controller callbacks return a Response' do
      let(:action_name) { :show }
      
      after do
        stage.run
      end
      it 'only calls the before callbacks' do
        expect(stage).to receive(:execute_callbacks).once.and_call_original
        expect(stage).to receive(:execute_controller_callbacks).once.and_call_original
      end
      it 'stops executing any other ones in the before chain' do
        expect($before_controller_callback).to receive(:call).once
      end
      it 'does not call "execute"' do
        expect(stage).to_not receive(:execute)
      end
      it 'does not execute any "after" callbacks either' do
        expect($after_controller_callback).to_not receive(:call)
      end
    end
  end

  context ".execute" do
    let(:double_stage_ok){ double("ok stage") }

    context 'when all stages suceed' do
      before do
        expect(double_stage_ok).to receive(:run).twice
        stage.instance_variable_set(:@stages, [double_stage_ok, double_stage_ok])
      end
      
      it "runs them all" do
        stage.execute
      end
      it 'returns nil' do
        expect( stage.execute ).to be(nil)
      end
    end
    context 'when one stage returns a Response' do
      it "runs no further stages after that" do
        double_stage_fail = double("fail stage")
        expect(double_stage_ok).to receive(:run).once
        expect(double_stage_fail).to receive(:run).once.and_return(Praxis::Responses::Ok.new)
        stage.instance_variable_set(:@stages, [double_stage_ok, double_stage_fail, double_stage_ok])
        stage.execute
      end
    end

  end


end
