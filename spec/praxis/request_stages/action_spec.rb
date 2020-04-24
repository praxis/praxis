require 'spec_helper'

describe Praxis::RequestStages::Action do

  let(:controller) do
    Class.new do
      include Praxis::Controller
    end.new(request)
  end

  let(:action) { double("action", name: "foo") }
  let(:response){ Praxis::Responses::Ok.new }
  let(:app){ double("App", controller: controller, action:action, request: request)}
  let(:action_stage){ Praxis::RequestStages::Action.new(action.name,app) }

  let(:request) do
    env = Rack::MockRequest.env_for('/instances/1?cloud_id=1&api_version=1.0')
    env['rack.input'] = StringIO.new('something=given')
    env['HTTP_VERSION'] = 'HTTP/1.1'
    env['HTTP_HOST'] = 'rightscale'
    request = Praxis::Request.new(env)
    request.action = action
    request
  end


  context '.execute' do
    before do
      expect(controller).to receive(action_stage.name) do |args|
        if args
          expect(args).to eq({})
        else
           expect(args).to eq(nil)
        end
      end.and_return(controller_response)
        
    end
    let(:controller_response){ controller.response }

    it 'always call the right controller method' do
      action_stage.execute
    end

    it 'saves the request reference inside the response' do
      action_stage.execute
      expect(controller.response.request).to eq(request)
    end

    it 'sends the right ActiveSupport::Notification' do
      expect(ActiveSupport::Notifications).to receive(:instrument).with('praxis.request_stage.execute', {controller: an_instance_of(controller.class)}).and_call_original
      action_stage.execute
    end

    context 'if the controller method returns a string' do
      let(:controller_response){ "this is the body"}
      it 'sets the response body with it (and save the request too)' do
        action_stage.execute
        expect(controller.response.body).to eq("this is the body")
      end
    end
    context 'if the controller method returns a response object' do
      let(:controller_response){ Praxis::Responses::Created.new }
      it 'set that response in the controller' do
        action_stage.execute
        expect(controller.response).to eq(controller_response)
      end
    end
    context 'if the controller method returns neither a string or a response' do
      let(:controller_response){ nil }
      it 'an error is raised ' do
        expect{ action_stage.execute }.to raise_error(/Only Response objects or Strings allowed/)
      end
    end
  end
end
