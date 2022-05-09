# frozen_string_literal: true

require 'spec_helper'

describe Praxis::Mapper::Resources::QueryProxy do
  let(:instance) { described_class.new(klass: resource_class) }
  let(:resource_class) { SimpleResource }
  let(:the_includes) { nil }

  context 'including' do
    let(:the_includes) { %i[one two] }
    it 'saves the includes' do
      expect(instance.instance_variable_get(:@_includes)).to be_nil
      result = instance.including(the_includes)
      expect(instance.instance_variable_get(:@_includes)).to be(the_includes)
      expect(result).to be instance
    end
  end

  context 'get' do
    subject { instance.get(id: 39) }
    # Base responds to the underlying ORM method _get to retrieve a record given a condition
    let(:base) { double('ORM Base', _get: model_instance) }

    before do
      expect(resource_class.model).to receive(:_add_includes) do |model, includes|
        expect(model).to be SimpleModel
        expect(includes).to be(the_includes)
      end.and_return(base)
    end
    context 'when a model is not found' do
      let(:model_instance) { nil }
      it 'returns nil' do
        expect(subject).to be nil
      end
    end

    context 'with a found model' do
      let(:model_instance) { SimpleModel.new }
      it 'returns an instance of the resource, wrapping the record' do
        expect(subject).to be_kind_of(SimpleResource)
        expect(subject.record).to be(model_instance)
      end
    end
  end

  context 'all' do
    subject { instance.all(id: 39, name: 'foo') }
    # Base responds to the underlying ORM method _all to retrieve a list of records given a condition
    let(:base) { double('ORM Base', _all: model_instances) }

    before do
      expect(resource_class.model).to receive(:_add_includes) do |model, includes|
        expect(model).to be SimpleModel
        expect(includes).to be(the_includes)
      end.and_return(base)
    end
    context 'when no records found' do
      let(:model_instances) { nil }
      it 'returns nil' do
        expect(subject).to be_empty
      end
    end

    context 'with found records' do
      let(:model_instances) { [SimpleModel.new(id: 1), SimpleModel.new(id: 2)] }
      it 'returns an array of resource instances, each wrapping their record' do
        expect(subject).to be_kind_of(Array)
        expect(subject.map(&:record)).to eq(model_instances)
      end
    end
  end

  context 'first' do
    subject { instance.first }
    before do
      expect(resource_class.model).to receive(:_first).and_return(model_instance)
    end
    context 'when a model is not found' do
      let(:model_instance) { nil }
      it 'returns nil' do
        expect(subject).to be nil
      end
    end

    context 'with a found model' do
      let(:model_instance) { SimpleModel.new }
      it 'returns an instance of the resource, wrapping the record' do
        expect(subject).to be_kind_of(SimpleResource)
        expect(subject.record).to be(model_instance)
      end
    end
  end

  context 'last' do
    subject { instance.last }
    before do
      expect(resource_class.model).to receive(:_last).and_return(model_instance)
    end
    context 'when a model is not found' do
      let(:model_instance) { nil }
      it 'returns nil' do
        expect(subject).to be nil
      end
    end

    context 'with a found model' do
      let(:model_instance) { SimpleModel.new }
      it 'returns an instance of the resource, wrapping the record' do
        expect(subject).to be_kind_of(SimpleResource)
        expect(subject.record).to be(model_instance)
      end
    end
  end

  context 'get!' do
    subject { instance.get!(id: 39) }
    before do
      # Expects to always call the normal get function for the result
      expect(instance).to receive(:get) do |args|
        expect(args[:id]).to eq(39)
      end.and_return(resource_instance)
    end
    context 'when no record is found' do
      let(:resource_instance) { nil }
      it 'raises ResourceNotFound' do
        expect{ subject }.to raise_error(Praxis::Mapper::ResourceNotFound)
      end
    end
    context 'with a record found' do
      let(:resource_instance) { double('ResourceInstance') }
      it 'simply returns the result of get' do
        expect(subject).to be(resource_instance)
      end
    end
  end
end
