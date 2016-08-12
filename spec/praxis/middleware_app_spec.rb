require 'spec_helper'

describe Praxis::MiddlewareApp do

  context '.for' do
    let(:init_args){ { root: 'here'} }
    subject(:middleware) { Praxis::MiddlewareApp.for( init_args ) }

    it 'initializes the application singletone with the passed parameters' do
      expect( Praxis::Application.instance ).to receive(:setup).with( init_args ).once
      subject
    end
    it 'returns its class' do
      expect( subject ).to be( Praxis::MiddlewareApp )
    end
  end

  context 'instantiated' do
    let(:target_response){ [201,{}] }
    let(:target){ double("target app", call: target_response) }
    subject(:instance){ Praxis::MiddlewareApp.new(target)}
    it 'saves the target app' do
      expect(subject.target).to be(target)
    end
    context '.call' do
      let(:env){ {} }
      let(:praxis_response){ [200,{}] }
      subject(:response){ Praxis::MiddlewareApp.new(target).call(env) }
      before do
        # always invokes the praxis app
        expect( Praxis::Application.instance ).to receive(:call).with( env ).once.and_return(praxis_response)
      end

      context 'properly handled (non-404 and 405) responses from praxis' do
        it 'are returned straight through' do
          expect( response ).to be(praxis_response)
        end
      end

      context '404/405 responses with X-Cascade = pass' do
        let(:praxis_response){ [404, {'X-Cascade' => 'pass'}]}
        it 'are forwarded to the target app' do
          expect( response ).to be(target_response)
        end
      end

      context '404/405 responses without X-Cascade = pass' do
        let(:praxis_response){ [404, {}]}
        it 'returned straight through' do
          expect( response ).to be(praxis_response)
        end
      end
    end
  end
end
