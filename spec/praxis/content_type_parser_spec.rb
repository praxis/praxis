require 'spec_helper'

describe Praxis::ContentTypeParser do

  describe '.parse' do
    context 'when content type is blank'  do
      it 'complains' do
        expect{ subject.parse(nil) }.to  raise_error(ArgumentError)
        expect{ subject.parse('') }.to   raise_error(ArgumentError)
        expect{ subject.parse('  ') }.to raise_error(ArgumentError)
     end
    end

    context 'when content type is weird'  do
      it 'complains' do
        expect{ subject.parse('+json') }.to raise_error(ArgumentError)
        expect{ subject.parse(';p1=2') }.to raise_error(ArgumentError)
     end
    end

    context 'when content type has only type'  do
      it 'returns the type only' do
        content_type = 'application/json'
        expectation  = {
          type: 'application/json'
        }
        expect(subject.parse(content_type)).to eq(expectation)
      end
    end

    context 'when content type has type and subtype'  do
      it 'returns both the type and the sub_type' do
        content_type = 'application/vnd.something+json'
        expectation  = {
          type:     'application/vnd.something',
          sub_type: 'json'
        }
        expect(subject.parse(content_type)).to eq(expectation)
      end
    end

    context 'when content type has type and params'  do
      it 'returns both the type and the params' do
        content_type = 'application/json;p1=2;no_value;foo=bar'
        expectation  = {
          type:   'application/json',
          params: {"p1"=>"2", "no_value"=>nil, "foo"=>"bar"}
        }
        expect(subject.parse(content_type)).to eq(expectation)
      end
    end

    context 'when content type has type, sub_type and params'  do
      it 'returns them all' do
        content_type = 'application/vnd.something+json;p1=2;no_value;foo=bar'
        expectation  = {
          type:     'application/vnd.something',
          sub_type: 'json',
          params:   {"p1"=>"2", "no_value"=>nil, "foo"=>"bar"}
        }
        expect(subject.parse(content_type)).to eq(expectation)
      end
    end


    context 'when there are spaces all around it should ignore them'  do
      it 'returns them all' do
        content_type = '  application/vnd.something+json ;   p1=2 ;no_value  ;  foo=bar ; '
        expectation  = {
          type:     'application/vnd.something',
          sub_type: 'json',
          params:   {"p1"=>"2", "no_value"=>nil, "foo"=>"bar"}
        }
        expect(subject.parse(content_type)).to eq(expectation)
      end
    end
  end
end
