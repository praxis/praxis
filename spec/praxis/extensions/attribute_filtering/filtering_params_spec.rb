require 'spec_helper'

require 'praxis/extensions/attribute_filtering'

describe Praxis::Extensions::AttributeFiltering::FilteringParams do

  context '.load' do
    subject { described_class.load(filters_string) }
    context 'parses for operator' do
      described_class::AVAILABLE_OPERATORS.each do |op|
        it "#{op}" do
          str = "thename#{op}thevalue"
          parsed = [{ name: :thename, op: op, value: 'thevalue'}]
          expect(described_class.load(str).parsed_array).to eq(parsed)
        end
      end
    end
    context 'with all operators at once' do
      let(:filters_string) { 'one=1&two!=2&three>=3&four<=4&five<5&six>6&seven!&eight!!'}
      it do
        expect(subject.parsed_array).to eq([
          { name: :one, op: '=', value: '1'},
          { name: :two, op: '!=', value: '2'},
          { name: :three, op: '>=', value: '3'},
          { name: :four, op: '<=', value: '4'},
          { name: :five, op: '<', value: '5'},
          { name: :six, op: '>', value: '6'},
          { name: :seven, op: '!', value: nil},
          { name: :eight, op: '!!', value: nil},          
        ])
      end
    end

    context 'with an associated MediaType' do
      let(:params_for_post_media_type) do
        # Note wrap the filter_params (.for) type in an attribute (which then we discard), so it will 
        # construct it propertly by applying the block. Seems easier than creating the type alone, and 
        # then manually apply the block
        Attributor::Attribute.new(described_class.for(Post)) do
          filter 'id', using: ['=', '!=', '!']
        end.type
      end

      context 'with a single value' do
        let(:str) { 'id=1' }
        it 'coerces its value to the associated mediatype attribute type' do
          parsed = params_for_post_media_type.load(str).parsed_array
          expect(parsed.first).to eq(:name=>:id, :op=>"=", :value=>1)
          expect(Post.attributes[:id].type.valid_type?(parsed.first[:value])).to be_truthy
        end
      end

      context 'with multimatch' do
        let(:str) { 'id=1,2,3' }
        it 'coerces ALL csv values to the associated mediatype attribute type' do
          parsed = params_for_post_media_type.load(str).parsed_array
          expect(parsed.first).to eq(:name=>:id, :op=>"=", :value=>[1, 2, 3])
          parsed.first[:value].each do |val|
            expect(Post.attributes[:id].type.valid_type?(val)).to be_truthy
          end
        end
      end

      context 'with a single value that is null' do
        let(:str) { 'id!' }
        it 'properly loads it as null' do
          parsed = params_for_post_media_type.load(str).parsed_array
          expect(parsed.first).to eq(:name=>:id, :op=>"!", :value=>nil)
        end
      end
    end

  end

  context '.validate' do
    let(:filtering_params_type) do
      # Note wrap the filter_params (.for) type in an attribute (which then we discard), so it will 
      # construct it propertly by applying the block. Seems easier than creating the type alone, and 
      # then manually apply the block
      Attributor::Attribute.new(described_class.for(Post)) do
        filter 'id', using: ['=', '!=']
        filter 'title', using: ['=', '!='], fuzzy: true
        filter 'content', using: ['=', '!=']
      end.type
    end
    let(:loaded_params) { filtering_params_type.load(filters_string) }
    subject { loaded_params.validate(filters_string) }

    context 'errors' do
      context 'given attributes that do not exist in the type' do
        let(:filters_string) { 'NotAnExistingAttribute=Foobar*'}
        it 'raises an error' do
          expect{subject}.to raise_error(/NotAnExistingAttribute.*does not exist/)
        end
      end

      context 'given unallowed attributes' do
        let(:filters_string) { 'href=Foobar*'}
        it 'raises an error' do
          expect(subject).to_not be_empty
          matches_error = subject.any? {|err| err =~ /Filtering by href is not allowed/}
          expect(matches_error).to be_truthy
        end
      end

      context 'given unallowed operator' do
        let(:filters_string) { 'title>Foobar*'}
        it 'raises an error' do
          expect(subject).to_not be_empty
          expect(subject.first).to match(/Operator > not allowed for filter title/)
        end
      end
    end
    context 'fuzzy matches' do
      context 'when allowed' do
        context 'given a fuzzy string' do
          let(:filters_string) { 'title=IAmAString*'}
          it 'validates properly' do
            expect(subject).to be_empty
          end
        end
      end
      context 'when NOT allowed' do
        context 'given a fuzzy string' do
          let(:filters_string) { 'content=IAmAString*'}
          it 'errors out' do
            expect(subject).to_not be_empty
            expect(subject.first).to match(/Fuzzy matching for content is not allowed/)
          end
        end
        context 'given a non-fuzzy string' do
          let(:filters_string) { 'content=IAmAString'}
          it 'validates properly' do
            expect(subject).to be_empty
          end
        end
      end
    end
  end
end
