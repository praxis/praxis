require 'spec_helper'

describe Praxis::RequestStages::Validate do
  let(:dispatcher) { Praxis::Dispatcher.new }

  # Instances controller is defined in the 'app' folder and is already in scope. Using this
  # controller for the specs instead of creating a simple controller.
  let(:controller) { Instances }

  let(:action) { controller.definition.actions[:show] }

  let(:env) do
    e = Rack::MockRequest.env_for('/instances/1?cloud_id=1&api_version=1.0')
    e['rack.input'] = StringIO.new('something=given')
    e['HTTP_VERSION'] = 'HTTP/1.1'
    e['HTTP_HOST'] = 'rightscale'
    e
  end

  let(:request) do
    r = Praxis::Request.new(env)
    r.route_params = { id: 1 }
    r.action = action
    r
  end

  context 'given a request' do
    it 'should validate params and headers from the request' do
      expect(request).to receive(:validate_headers).and_return([])
      expect(request).to receive(:validate_params).and_return([])
      dispatcher.dispatch(controller, action, request)
    end

    it 'should validate payload from the request' do
      expect(request).to receive(:validate_payload).and_return([])
      dispatcher.dispatch(controller, action, request)
    end
  end
end
