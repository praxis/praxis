require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Praxis::RequestStages::Validate do
  let(:dispatcher) { Praxis::Dispatcher.new }

  # Instances controller is defined in the 'app' folder and is already in scope. Using this
  # controller for the specs instead of creating a simple controller.
  let(:controller) { Instances }

  let(:action) { controller.definition.actions[:show] }

  let(:request) do
    env = Rack::MockRequest.env_for('/instances/1?cloud_id=1&api_version=1.0')
    env['rack.input'] = StringIO.new('something=given')
    env['HTTP_VERSION'] = 'HTTP/1.1'
    env['HTTP_HOST'] = 'rightscale'
    request = Praxis::Request.new(env)
    request.action = action
    request
  end

  context 'given a request' do
    it 'should validate params and headers from the request' do
      expect(request).to receive(:validate_headers)
      expect(request).to receive(:validate_params)
      dispatcher.dispatch(controller, action, request)
    end

    it 'should validate payload from the request' do
      expect(request).to receive(:validate_payload)
      dispatcher.dispatch(controller, action, request)
    end
  end
end
