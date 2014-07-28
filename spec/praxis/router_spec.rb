require 'spec_helper'

describe Praxis::Router do
  describe Praxis::Router::RequestRouter do
    subject(:request_router) {Praxis::Router::RequestRouter.new}
    let(:request) {double("request", route_params: '', path: 'path')}
    let(:callback) {double("callback")}

    context ".invoke" do
      it "update request and call request for callback" do
        request.stub(:route_params=)
        callback.stub("call").and_return(1)

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

  subject(:router) {Praxis::Router.new}
  context "attributes" do
    its(:request_class) {should be(Praxis::Request)}
  end

  context ".add_route" do
    let(:route) {double('route', options: [1], version: 1, verb: 'verb', path: 'path')}

    it "rise warning with options in route" do
      router.should_receive(:warn).with("other conditions not supported yet")
      expect(router.add_route(proc {'target'},route)).to eq(['path'])
    end
  end

  context ".call" do
    let(:request) {Praxis::Request.new({})}
    it "calls the route with params request" do
      Praxis::Router::RequestRouter.any_instance.stub(:call).with(request).and_return(1)
      expect(router.call(request)).to eq(1)
    end
  end
end
