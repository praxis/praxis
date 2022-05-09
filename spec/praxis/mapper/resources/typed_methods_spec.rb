# frozen_string_literal: true

require 'spec_helper'

describe Praxis::Mapper::Resources::TypedMethods do
  let(:resource_class) { TypedResource }

  context '._finalize!' do
    # The class is already finalized by loading the TypedResource from the spec_resources
    # So we will simply check that all the right things are created
    it 'builds the MethodSignatures constant within the class' do
      expect(TypedResource::MethodSignatures).to_not be_nil
    end

    it 'builds the inner class type for the defined signatures' do
      expect(TypedResource::MethodSignatures::UpdateBang).to_not be_nil
      expect(TypedResource::MethodSignatures::UpdateBang).to be TypedResource.signature(:update!)

      expect(TypedResource::MethodSignatures::Create).to_not be_nil
      expect(TypedResource::MethodSignatures::Create).to be TypedResource.signature(:create)
    end

    it 'Subsitutes a ! for a Bang when creating the constant' do
      expect(TypedResource::MethodSignatures::UpdateBang).to be TypedResource.signature(:update!)
    end

    it 'defines the coercing methods' do
      expect(TypedResource.methods).to include(:_coerce_params_for_class_create)
      expect(TypedResource.instance_methods).to include(:_coerce_params_for_update!)
    end
  end

  context '.signature' do
    # We are not creating more classes and signatures, simply checking that the ones created
    # for TypedResoruce in the spec_resource_files are correctly processed
    it 'defines it in the @signatures hash' do
      expect(TypedResource.signatures.keys).to include(:create, :update!)
      expect(TypedResource.signature(:create)).to be < Attributor::Struct
      expect(TypedResource.signature(:update!)).to be < Attributor::Struct
    end

    it 'holds the right definition for create' do
      definition = TypedResource.signature(:create)
      expect(definition.attributes.keys).to eq %i[name payload]
      expect(definition.attributes[:payload].attributes.keys).to eq %i[string_param struct_param]
    end

    it 'holds the right definition for create' do
      definition = TypedResource.signature(:update!)
      expect(definition.attributes.keys).to eq %i[string_param struct_param]
      expect(definition.attributes[:struct_param].attributes.keys).to eq %i[id]
    end
  end

  context 'coerce_params_for' do
    let(:resource_class) do
      Class.new(Praxis::Mapper::Resource) do
        include Praxis::Mapper::Resources::TypedMethods
        def imethod(args)
          args
        end

        def self.cmethod(args)
          args
        end
      end
    end

    let(:hook_coercer) { resource_class.coerce_params_for(method, type) }
    # Note, we're associating the same type signature for both imethod and cmethod!
    let(:type) do
      Class.new(Attributor::Struct) do
        attributes do
          attribute :id, Integer, required: true
          attribute :name, String, null: false
        end
      end
    end

    before do
      # None of our wrappers before invoking the function
      our_wrappers = resource_class.methods.select { |m| m.to_s =~ /^_coerce_params_for_class_/ }
      our_wrappers +=  resource_class.instance_methods.select { |m| m.to_s =~ /^_coerce_params_for_/ }
      expect(our_wrappers).to be_empty
    end
    context 'instance methods' do
      let(:method) { :imethod }
      it 'creates the wrapper methods' do
        hook_coercer
        iwrappers = resource_class.instance_methods.select { |m| m.to_s =~ /^_coerce_params_for_/ }
        expect(iwrappers).to eq [:_coerce_params_for_imethod]
      end

      it 'sets an around callback for them' do
        hook_coercer
        expect(resource_class.around_callbacks[:imethod]).to eq([:_coerce_params_for_imethod])
      end

      context 'when hooking in the callbacks' do
        before do
          hook_coercer
          resource_class._finalize!
        end
        context 'calls the wrapper to validate and load' do
          it 'fails if invalid (id is required)' do
            expect do
              resource_class.new(nil).imethod(name: 'Praxis')
            end.to raise_error(
              Praxis::Mapper::Resources::IncompatibleTypeForMethodArguments,
              /.imethod.id is required/
            )
          end

          it 'succeeds and returns the coerced struct if compatible' do
            result = resource_class.new(nil).imethod(id: '1', name: 'Praxis')
            expect(result.id).to eq(1) # Coerces to Integer!
            expect(result.name).to eq('Praxis')
          end
        end
      end
    end

    context 'class methods' do
      let(:method) { :cmethod }
      it 'creates the wrapper methods' do
        hook_coercer
        cwrappers = resource_class.methods.select { |m| m.to_s =~ /^_coerce_params_for_class_/ }
        expect(cwrappers).to eq [:_coerce_params_for_class_cmethod]
      end

      it 'sets an around callback for them' do
        hook_coercer
        expect(resource_class.around_callbacks[:cmethod]).to eq([:_coerce_params_for_class_cmethod])
      end

      context 'when hooking in the callbacks' do
        before do
          hook_coercer
          resource_class._finalize!
        end
        context 'calls the wrapper to validate and load' do
          it 'fails if invalid (id is required)' do
            expect do
              resource_class.cmethod(name: 'Praxis')
            end.to raise_error(
              Praxis::Mapper::Resources::IncompatibleTypeForMethodArguments,
              /.cmethod.id is required/
            )
          end

          it 'succeeds and returns the coerced struct if compatible' do
            result = resource_class.cmethod(id: '1', name: 'Praxis')
            expect(result.id).to eq(1) # Coerces to Integer!
            expect(result.name).to eq('Praxis')
          end
        end
      end
    end
  end
end
