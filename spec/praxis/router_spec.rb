require 'spec_helper'

describe Praxis::Router do
  describe Praxis::Router::RequestRouter do

    let(:request) {double("request", route_params: '', path: 'path')}
    let(:callback) {double("callback")}
  
    subject(:request_router) {Praxis::Router::RequestRouter.new}

    context ".invoke" do
      it "update request and call request for callback" do
        allow(request).to receive(:route_params=)
        allow(callback).to receive(:call).and_return(1)

        invoke_call = request_router.invoke(callback, request, "params", "pattern")
        expect(invoke_call).to eq(1)
      end
    end

    context ".string_for" do
      it "returns request path string" do
        expect(request_router.string_for(request)).to eq('path')
      end
    end
  end

  let(:application) { instance_double('Praxis::Application')}
  subject(:router) {Praxis::Router.new(application)}

  context "attributes" do
    its(:request_class) {should be(Praxis::Request)}
  end

  context ".add_route" do
    let(:route) {double('route', options: [1], version: 1, verb: 'verb', path: 'path')}

    it "raises warning when options are specified in route" do
      expect(router).to receive(:warn).with("other conditions not supported yet")
      expect(router.add_route(proc {'target'},route)).to eq(['path'])
    end
  end

  context ".call" do
    let(:request) {Praxis::Request.new({})}
    it "calls the route with params request" do
      allow_any_instance_of(Praxis::Router::RequestRouter).
        to receive(:call).with(request).and_return(1)
      expect(router.call(request)).to eq(1)
    end
  end
end
