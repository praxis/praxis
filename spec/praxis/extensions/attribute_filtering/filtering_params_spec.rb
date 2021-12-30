# frozen_string_literal: true

require 'spec_helper'

require 'praxis/extensions/attribute_filtering'

describe Praxis::Extensions::AttributeFiltering::FilteringParams do
  context '.load' do
    subject { described_class.load(filters_string) }

    context 'unescapes the URL encoded values' do
      it 'for single values' do
        str = "one=#{CGI.escape('*')}&two>#{CGI.escape('^%$#!st_uff')}|three<normal"
        parsed = [
          { name: :one, op: '=', value: '*' },
          { name: :two, op: '>', value: '^%$#!st_uff' },
          { name: :three, op: '<', value: 'normal' }
        ]
        expect(described_class.load(str).parsed_array.map { |i| i.slice(:name, :op, :value) }).to eq(parsed)
      end
      it 'each of the multi-values' do
        escaped_one = [
          CGI.escape('fun!'),
          CGI.escape('Times'),
          CGI.escape('~!@#$%^&*()_+-={}|[]\:";\'<>?,./`')
        ].join(',')
        str = "one=#{escaped_one}&two>normal"
        parsed = [
          { name: :one, op: '=', value: ['fun!', 'Times', '~!@#$%^&*()_+-={}|[]\:";\'<>?,./`'] },
          { name: :two, op: '>', value: 'normal' }
        ]
        expect(described_class.load(str).parsed_array.map { |i| i.slice(:name, :op, :value) }).to eq(parsed)
      end
      it 'does not handle badly escaped values that contain reserved chars ()|&,' do
        badly_escaped = 'val('
        str = "one=#{badly_escaped}&(two>normal|three!)"
        expect do
          described_class.load(str)
        end.to raise_error(Parslet::ParseFailed)
      end
    end
    context 'parses for operator' do
      described_class::VALUE_OPERATORS.each do |op|
        it op.to_s do
          str = "thename#{op}thevalue"
          parsed = [{ name: :thename, op: op, value: 'thevalue' }]
          expect(described_class.load(str).parsed_array.map { |i| i.slice(:name, :op, :value) }).to eq(parsed)
        end
      end
      described_class::NOVALUE_OPERATORS.each do |op|
        it op.to_s do
          str = "thename#{op}"
          parsed = [{ name: :thename, op: op, value: nil }]
          expect(described_class.load(str).parsed_array.map { |i| i.slice(:name, :op, :value) }).to eq(parsed)
        end
      end
      it 'can parse multiple values for filter' do
        str = 'filtername=1,2,3'
        parsed = [{ name: :filtername, op: '=', value: %w[1 2 3] }]
        expect(described_class.load(str).parsed_array.map { |i| i.slice(:name, :op, :value) }).to eq(parsed)
      end
    end
    context 'with all value operators at once for the same AND group' do
      let(:filters_string) { 'one=11&two!=22&three>=33&four<=4&five<5&six>6&seven!&eight!!' }
      it do
        expect(subject.parsed_array.map { |i| i.slice(:name, :op, :value) }).to eq([
                                                                                     { name: :one, op: '=', value: '11' },
                                                                                     { name: :two, op: '!=', value: '22' },
                                                                                     { name: :three, op: '>=', value: '33' },
                                                                                     { name: :four, op: '<=', value: '4' },
                                                                                     { name: :five, op: '<', value: '5' },
                                                                                     { name: :six, op: '>', value: '6' },
                                                                                     { name: :seven, op: '!', value: nil },
                                                                                     { name: :eight, op: '!!', value: nil }
                                                                                   ])
        # And all have the same parent, which is an AND group
        parent = subject.parsed_array.map { |i| i[:node_object].parent_group }.uniq
        expect(parent.size).to eq(1)
        expect(parent.first.type).to eq(:and)
        expect(parent.first.parent_group).to be_nil
      end
    end

    context 'with with nested precedence groups' do
      let(:filters_string) { '(one=11)&(two!=22|three!!)&four<=4&five>5|six!' }
      it do
        parsed = subject.parsed_array
        expect(parsed.map { |i| i.slice(:name, :op, :value) }).to eq([
                                                                       { name: :one, op: '=', value: '11' },
                                                                       { name: :two, op: '!=', value: '22' },
                                                                       { name: :three, op: '!!', value: nil },
                                                                       { name: :four, op: '<=', value: '4' },
                                                                       { name: :five, op: '>', value: '5' },
                                                                       { name: :six, op: '!', value: nil }
                                                                     ])
        # Grouped appropriately
        parent_of = parsed.each_with_object({}) do |item, hash|
          hash[item[:name]] = item[:node_object].parent_group
        end
        # This is the expected tree grouping result
        # OR -- six
        #  |--- AND --five
        #        |--- four
        #        |--- OR -- three
        #        |     |--- two
        #        |--- one
        # two and 3 are grouped together by an OR
        expect(parent_of[:two]).to be(parent_of[:three])
        expect(parent_of[:two].type).to eq(:or)

        # one, two, four and the or from two/three are grouped together by an AND
        expect([parent_of[:one], parent_of[:two].parent_group, parent_of[:four], parent_of[:five]]).to all(be(parent_of[:one]))
        expect(parent_of[:one].type).to eq(:and)

        # six and the whole group above are grouped together with an OR
        expect(parent_of[:six]).to be(parent_of[:one].parent_group)
        expect(parent_of[:six].type).to eq(:or)
      end
    end

    context 'value coercing when associated to a MediaType' do
      let(:parsed) do
        # Note wrap the filter_params (.for) type in an attribute (which then we discard), so it will
        # construct it propertly by applying the block. Seems easier than creating the type alone, and
        # then manually apply the block
        Attributor::Attribute.new(described_class.for(Post)) do
          filter 'id', using: ['=', '!=', '!']
          any 'updated_at', using: ['>', '<', '=']
        end.type.load(str).parsed_array
      end

      context 'with a single value' do
        let(:str) { 'id=1' }
        it 'coerces its value to the associated mediatype attribute type' do
          expect(parsed.first[:value]).to eq(1)
          expect(Post.attributes[:id].type.valid_type?(parsed.first[:value])).to be_truthy
        end
      end

      context 'with multimatch' do
        let(:str) { 'id=1,2,3' }
        it 'coerces ALL csv values to the associated mediatype attribute type' do
          expect(parsed.first[:value]).to eq([1, 2, 3])
          parsed.first[:value].each do |val|
            expect(Post.attributes[:id].type.valid_type?(val)).to be_truthy
          end
        end
      end

      context 'with a single value that is null' do
        let(:str) { 'id!' }
        it 'properly loads it as null' do
          expect(parsed.first[:value]).to be_nil
        end
      end

      context 'for an ANY matcher' do
        let(:str) { 'blog.timestamps.updated_at>=2001-01-01' }
        it 'coerces its value to the associated mediatype attribute type' do
          expect(parsed.first[:value]).to eq(DateTime.parse('2001-01-01'))
          nested_updated_at_attr = Post.attributes[:blog].attributes[:timestamps].attributes[:updated_at]
          expect(nested_updated_at_attr.type.valid_type?(parsed.first[:value])).to be_truthy
        end
      end

      context 'for both normal and ANY type filters' do
        let(:str) { 'blog.timestamps.updated_at>=2001-01-01&id=42' }
        it 'properly parsed them both, and into their own types' do
          expect(parsed.first[:value]).to eq(DateTime.parse('2001-01-01'))
          nested_updated_at_attr = Post.attributes[:blog].attributes[:timestamps].attributes[:updated_at]
          expect(nested_updated_at_attr.type.valid_type?(parsed.first[:value])).to be_truthy

          expect(parsed.second[:value]).to eq(42)
          id_attr = Post.attributes[:blog].attributes[:id]
          expect(id_attr.type.valid_type?(parsed.second[:value])).to be_truthy
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
        filter 'id', using: ['=', '!=', '!']
        filter 'title', using: ['=', '!='], fuzzy: true
        filter 'content', using: ['=', '!=', '!']
        any 'updated_at', using: ['>', '<', '=']
      end.type
    end
    let(:loaded_params) { filtering_params_type.load(filters_string) }
    subject { loaded_params.validate(filters_string) }

    context 'errors' do
      context 'given attributes that do not exist in the type' do
        let(:filters_string) { 'NotAnExistingAttribute=Foobar*' }
        it 'raises an error' do
          expect { subject }.to raise_error(/NotAnExistingAttribute.*does not exist/)
        end
      end

      context 'given unallowed attributes' do
        let(:filters_string) { 'href=Foobar*' }
        it 'raises an error' do
          expect(subject).to_not be_empty
          matches_error = subject.any? { |err| err =~ /Filtering by href is not allowed.*leaf attributes matching updated_at/ }
          expect(matches_error).to be_truthy
        end
      end

      context 'given unallowed operator' do
        let(:filters_string) { 'title>Foobar*' }
        it 'raises an error' do
          expect(subject).to_not be_empty
          expect(subject.first).to match(/Operator > not allowed for filter title/)
        end
      end
    end

    context 'for any-type leaf filters' do
      context 'with the correct operator' do
        let(:filters_string) { 'timestamps.updated_at>2001-01-01' }
        it 'succeeds' do
          expect(subject).to be_empty
        end
      end
      context 'with the correct operator on a nested mediatype' do
        let(:filters_string) { 'blog.timestamps.updated_at>2001-01-01' }
        it 'succeeds' do
          expect(subject).to be_empty
        end
      end
      context 'with an incorrect operator' do
        let(:filters_string) { 'blog.timestamps.updated_at>=2001-01-01' }
        it 'complains about it' do
          expect(subject).to_not be_empty
          expect(subject.first).to match(/Operator >= not allowed for filter blog.timestamps.updated_at/)
        end
      end
      context 'with an correct operator but passing an unexistent attribute path' do
        let(:filters_string) { 'some.not.true.path.updated_at>=2001-01-01' }
        it 'complains about it' do
          expect { subject }.to raise_error(/Error, you've requested to filter by field 'some'/)
        end
      end
    end

    context 'non-valued operators' do
      context 'for string typed fields' do
        let(:filters_string) { 'content!' }
        it 'validates properly' do
          expect(subject).to be_empty
        end
      end
      context 'for non-string typed fields' do
        let(:filters_string) { 'id!' }
        it 'validates properly' do
          expect(subject).to be_empty
        end
      end
    end
    context 'fuzzy matches' do
      context 'when allowed' do
        context 'given a fuzzy string' do
          let(:filters_string) { 'title=IAmAString*' }
          it 'validates properly' do
            expect(subject).to be_empty
          end
        end
      end
      context 'when NOT allowed' do
        context 'given a fuzzy string' do
          let(:filters_string) { 'content=IAmAString*' }
          it 'errors out' do
            expect(subject).to_not be_empty
            expect(subject.first).to match(/Fuzzy matching for content is not allowed/)
          end
        end
        context 'given a non-fuzzy string' do
          let(:filters_string) { 'content=IAmAString' }
          it 'validates properly' do
            expect(subject).to be_empty
          end
        end
      end
    end
  end
end
