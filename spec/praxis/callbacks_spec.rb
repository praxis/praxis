require 'spec_helper'

describe Praxis::Callbacks do
  let(:controller){ double("controller", request: "request") }
  
  subject do
    Class.new {
      include Praxis::Callbacks

#      implements PeopleResource

      before :validate, actions: [:index] do |controller|
        "before"
      end

      before actions: [:show] do |controller|
      end

      after :response, actions: [:show] do |controller|
        "after"
      end

      around :action , actions: [:foobar] do |controller, callee|
        controller.request
        callee.call
      end
    }
  end
  
  context '.before' do
    let(:validate_conditions) { subject.before_callbacks[[:validate]][0][0] }
    let(:validate_block) { subject.before_callbacks[[:validate]][0][1] }

    it 'sets up the before_callbacks' do
      expect(subject.before_callbacks.keys).to match_array([[:validate], [:action]])
      expect(validate_conditions).to eq({:actions => [:index]})
      expect(validate_block).to be_kind_of(Proc)
      expect(validate_block.call(controller)).to eq("before")
    end
  end

  context '.after' do
    let(:response_conditions) { subject.after_callbacks[[:response]][0][0] }
    let(:response_block) { subject.after_callbacks[[:response]][0][1] }

    it 'sets up the after_callbacks' do
      expect(subject.after_callbacks.keys).to match_array([[:response]])
      expect(response_conditions).to eq({:actions => [:show]})
      expect(response_block).to be_kind_of(Proc)
      expect(response_block.call(controller)).to eq("after")
    end
  end
  

  context '.around' do
    let(:callee_result){ "result" }
    let(:callee){ double("callee", call: callee_result) }
    let(:around_conditions) { subject.around_callbacks[[:action]][0][0] }
    let(:around_block) { subject.around_callbacks[[:action]][0][1] }

    it 'sets up the before_callbacks' do
      expect(subject.around_callbacks.keys).to match_array([[:action]])
      expect(around_conditions).to eq({:actions => [:foobar]})
      expect(around_block).to be_kind_of(Proc)
    end
    it 'passes the right parameters to the block call' do
      expect(controller).to receive(:request)
      expect(callee).to receive(:call)
      expect(around_block.call( controller,callee )).to eq(callee_result)
    end
  end
  
  # DONT DO THIS...this is just a test to show what would happen
  context 'inheriting callbacks from base classes ' do
    let!(:child1) {
      Class.new(subject) do
        before actions: [:child1] do |controller|
          "before show child1"
        end
      end
    }
    let!(:child2) {
      Class.new(subject) do
        before actions: [:child2] do |controller|
          "before show child2"
        end
      end
    }

    describe '.before_callbacks (but same for after and around)' do
      context 'for child1 (and viceversa for child2)' do
        let(:inherited_callbacks){ child1.before_callbacks }
        it "will inherits not just the base callbacks, but child2 also!" do
          expect(inherited_callbacks).to be_a(Hash)
          expect(inherited_callbacks.keys).to eq([[:validate],[:action]])
          action_callbacks = inherited_callbacks[[:action]]
          expect(action_callbacks).to have(3).items
          action_callback_options = action_callbacks.map{|options, block| options}
          expect(action_callback_options).to eq([{:actions=>[:show]}, 
                                                 {:actions=>[:child1]}, 
                                                 {:actions=>[:child2]}])
        end
      end
    end

  end
end
