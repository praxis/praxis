require 'spec_helper'

describe Praxis::Router do
  let(:application) do
    app = Praxis::Application.new(skip_registration: true)
    app.versioning_scheme = [:header, :params]
    app
  end
  describe Praxis::Router::VersionMatcher do
    let(:resource_definition){ double("resource_definition", version_options: { using: [:header, :params] }) }
    let(:action){ double("action", resource_definition: resource_definition ) }
    let(:target){ double("target", action: action ) }
    let(:args){ {version: "1.0"} }
    subject(:matcher){ Praxis::Router::VersionMatcher.new(target,args) }

    context '.initialize' do
      let(:args){ {} }
      it 'defaults to no version' do
        expect( matcher.instance_variable_get(:@version) ).to eq("n/a")
      end
    end

    context '.call' do
      let(:env){ {"HTTP_X_API_VERSION" => request_version } }
      let(:request) {Praxis::Request.new(env,application: application)}

      context 'with matching versions' do
        let(:request_version) { "1.0" }
        it 'calls the target' do
          expect(target).to receive(:call).with(request)
          matcher.call(request)
        end
      end

      context 'with non-matching versions' do
        let(:request_version) { "4.0" }
        before do
          expect { matcher.call(request) }.to throw_symbol(:pass)
        end
        it 'does not call the target' do
          expect( target ).not_to receive(:call).with(request)
        end
        it 'saves the unmatched version' do
          expect( request.unmatched_versions ).to include(args[:version])
        end
      end

    end
  end

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

  subject(:router) {Praxis::Router.new(application)}

  context "attributes" do
    its(:request_class) {should be(Praxis::Request)}
  end

  context ".add_route" do

    let(:route){ double('route', options: [1], version: 1, verb: 'verb', path: 'path')}
    let(:target){ double('target') }
    let(:verb_router){ double('verb_router') }

    let(:resource_definition) { double('resource_definition', version_options: {using: [:header, :params]} ) }
    let(:action) { double('action', resource_definition: resource_definition) }
    let(:target) { double('target', action: action) }


    context 'with params or header versioning' do
      it 'wraps the target with a VersionMatcher' do
        router.instance_variable_set( :@routes, {'verb'=>verb_router} ) # Ugly, but no need to have a reader
        expect(verb_router).to receive(:on) do|path, args|# .with(route.path, call: "foo")
          expect(path).to eq(route.path)
          expect(args).to be_kind_of(Hash)
          expect(args[:call]).to be_kind_of(Praxis::Router::VersionMatcher)
        end
        router.add_route(target, route)
      end
    end

  end

  context ".call" do
    let(:env){ {"PATH_INFO"=>request_path_info, "REQUEST_METHOD"=>request_verb} }
    let(:request_verb) { 'POST' }
    let(:request_path_info) { '/' }
    let(:request_version){ nil }
    let(:request) {Praxis::Request.new(env, application: application)}
    let(:router_response){ 1 }
    let(:router_response_for_post){ "POST result" }
    let(:router_response_for_wildcard){ "* result" }
    let(:post_target_router){ double("POST target", call: router_response_for_post) }
    let(:any_target_router){ double("ANY target", call: router_response_for_wildcard) }

    let(:resource_definition) { double('resource_definition', version_options: {using: [:header, :params]} ) }
    let(:action) { double('action', resource_definition: resource_definition) }
    let(:target) { double('target', action: action) }

    before do
      env['HTTP_X_API_VERSION'] = request_version if request_version
      allow_any_instance_of(Praxis::Router::RequestRouter).
        to receive(:call).with(request).and_return(router_response)
      router.add_route(target,double("route1", verb: 'POST', path: '/', options: {} , version: request_version))
      # Hijack the callable block in the routes (since there's no way to point back to the registered route object)
      router.instance_variable_get(:@routes)['POST'] = post_target_router

    end

    context 'for routes without wildcards (a single POST route)' do

      context 'and an incoming POST request' do
        it "finds a match and invokes it the route" do
          expect(router.call(request)).to eq(router_response_for_post)
        end
      end
      context 'and an incoming PUT request' do
        let(:request_verb) { 'PUT' }
        it "does not find a route" do
          response_code, _ , _ = router.call(request)
          expect(response_code).to be(404)
        end
      end
    end

    context 'for routes with wildcards (a POST and a * route)' do
      let(:resource_definition) { double('resource_definition', version_options: {using: [:header, :params]} ) }
      let(:action) { double('action', resource_definition: resource_definition) }
      let(:target) { double('target', action: action) }

      before do
        router.add_route(target,double("route2", verb: 'ANY', path: '/*', options: {} , version: request_version))
        # Hijack the callable block in the routes (since there's no way to point back to the registered route object)
        router.instance_variable_get( :@routes )['ANY'] = any_target_router
      end

      context 'and an incoming PUT request' do
        let(:request_verb) { 'PUT' }
        it "it can successfully find a match using the wildcard target" do
          expect(router.call(request)).to eq(router_response_for_wildcard)
        end
      end
      context 'and an incoming POST request' do
        it 'matches the most specific POST route, rather than the wildcard'do
          expect(router.call(request)).to eq(router_response_for_post)
        end
      end
      context 'and an incoming POST request (but that does not match other route conditions)' do
        let(:router_response_for_post){ :not_found }
        it 'still matches wildcard verb if that was route conditions-compatible' do
          expect(post_target_router).to receive(:call).once # try the match cause it's a POST
          expect(any_target_router).to receive(:call).once  # fallback to wildcard upon a not_found
          expect(router.call(request)).to eq(router_response_for_wildcard)
        end
      end
    end

    context "when not_found is returned" do
      let(:request_verb) { 'DELETE' }
      let(:router_response){ :not_found }


      it 'sets X-Cascade: pass by default' do
        _, headers, _ = router.call(request)
        expect(headers).to have_key('X-Cascade')
        expect(headers['X-Cascade']).to eq('pass')
      end

      context 'with X-Cascade disabled' do
        let(:config) { Praxis::Application.instance.config.praxis }
        before do
          expect(config).to receive(:x_cascade).and_return(false)
        end

        it 'does not set X-Cascade: pass' do
          _, headers, _ = router.call(request)
          expect(headers).to_not have_key("X-Cascade")
        end

      end

      context 'with versioning' do
        before do
          request.instance_variable_set(:@unmatched_versions, unmatched_versions)
        end

        context "having passed no version in the request" do
          context 'and no controllers matching the path' do
            let(:unmatched_versions) { Set.new([]) }

            it 'returns a basic "NotFound" response: 404 status, text/plain content and "NotFound" body' do
              expect( router.call(request) ).to eq([404, {"Content-Type" => "text/plain","X-Cascade"=>"pass"}, ["NotFound"]])
            end
          end

          context 'and some controllers matching the path' do
            let(:unmatched_versions) { Set.new(["1.0"]) }
            it 'returns a specific body response noting which request versions would matched if passed in' do
              _, _, body = router.call(request)
              expect( body.first ).to eq('NotFound. Your request did not specify an API version. Available versions = "1.0".')
            end
          end
        end

        context "having passed a version in the request" do

          context 'but having no controllers matching the path part' do
            let(:request_version) { "50.0" }
            let(:unmatched_versions) { Set.new(["1.0","2.0"]) }

            it 'returns a specific body response noting that the version might be wrong (and which could be right)' do
              code, headers, body = router.call(request)
              expect(code).to eq(404)
              expect(headers['Content-Type']).to eq('text/plain')
              expect(body.first).to eq("NotFound. Your request specified API version = \"#{request_version}\". Available versions = \"1.0\", \"2.0\".")
            end
          end
        end
      end


    end
  end
end
