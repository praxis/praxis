require 'praxis/extensions/attribute_filtering/filters_parser'


describe Praxis::Extensions::AttributeFiltering::FilteringParams::Condition do
end 

describe Praxis::Extensions::AttributeFiltering::FilteringParams::ConditionGroup do
end 

describe Praxis::Extensions::AttributeFiltering::FilteringParams::Parser do

  context 'testing' do
    let(:expectations) do
      { 
        'one=11|two=22' => "( one=11 OR two=22 )"
      }
    end
    it 'parses and loads the parsed result into the tree objects' do
      expectations.each do |filters, dump_result|

        parsed = described_class.new.parse(filters)
        tree = Praxis::Extensions::AttributeFiltering::FilteringParams::ConditionGroup.load(parsed)

        expect(tree.dump).to eq(dump_result)
      end
    end
  end
   context 'parses the grammar' do

    # Takes a hash with keys containing literal filters string, and values being the "dump format for Condition/Group"
    shared_examples 'round-trip-properly' do |expectations|
      it description do
        expectations.each do |filters, dump_result|
          parsed = Praxis::Extensions::AttributeFiltering::FilteringParams::Parser.new.parse(filters)
          tree = Praxis::Extensions::AttributeFiltering::FilteringParams::ConditionGroup.load(parsed)
          expect(tree.dump).to eq(dump_result)
        end
      end
    end

    context 'single expression' do
      it_behaves_like 'round-trip-properly', { 
        'one=11' => 'one=11',
        '(one=11)' => 'one=11',
        'one!' => "one!",
      }
    end
    context 'same expression operator' do
      it_behaves_like 'round-trip-properly', { 
        'one=11&two=22' => '( one=11 AND two=22 )',
        'one=11&two=22&three=3' => '( one=11 AND two=22 AND three=3 )',
        'one=1,2,3&two=4,5' => '( one=[1,2,3] AND two=[4,5] )',
        'one=11|two=22' => '( one=11 OR two=22 )',
        'one=11|two=22|three=3' => '( one=11 OR two=22 OR three=3 )',
      }
    end

    context 'respects and/or precedence and parenthesis grouping' do
      it_behaves_like 'round-trip-properly', { 
        'a=1&b=2&z=9|c=3' => '( ( a=1 AND b=2 AND z=9 ) OR c=3 )',
        'a=1|b=2&c=3' => '( a=1 OR ( b=2 AND c=3 ) )',
        'a=1|b=2&c=3&d=4' => '( a=1 OR ( b=2 AND c=3 AND d=4 ) )',
        '(a=1|b=2)&c=3&d=4' => '( ( a=1 OR b=2 ) AND c=3 AND d=4 )',
        'a=1|a.b.c_c=1&b=2' => '( a=1 OR ( a.b.c_c=1 AND b=2 ) )',
        'a=1,2,3|b=4,5&c=one,two' => '( a=[1,2,3] OR ( b=[4,5] AND c=[one,two] ) )',
        'one=11&two=2|three=3' => '( ( one=11 AND two=2 ) OR three=3 )', # AND has higer precedence
        'one=11|two=2&three=3' => '( one=11 OR ( two=2 AND three=3 ) )', # AND has higer precedence
        'one=11&two=2|three=3&four=4' => '( ( one=11 AND two=2 ) OR ( three=3 AND four=4 ) )',
        '(one=11)&(two!=2|three=3)&four=4&five=5|six=6' => 
            '( ( one=11 AND ( two!=2 OR three=3 ) AND four=4 AND five=5 ) OR six=6 )',
        '(one=11)&three=3' => '( one=11 AND three=3 )',
        '(one=11|two=2)&(three=3|four=4)' => '( ( one=11 OR two=2 ) AND ( three=3 OR four=4 ) )',
        '(category_uuid=deadbeef1|category_uuid=deadbeef2)&(name=Book1|name=Book2)' =>
            '( ( category_uuid=deadbeef1 OR category_uuid=deadbeef2 ) AND ( name=Book1 OR name=Book2 ) )',
        '(category_uuid=deadbeef1&name=Book1)|(category_uuid=deadbeef2&name=Book2)' =>
            '( ( category_uuid=deadbeef1 AND name=Book1 ) OR ( category_uuid=deadbeef2 AND name=Book2 ) )',
      }
    end

    context 'empty values get converted to empty strings' do
      it_behaves_like 'round-trip-properly', { 
        'one=' => 'one=""',
        'one=&two=2' => '( one="" AND two=2 )',
      }
    end

    context 'no value operands' do
      it_behaves_like 'round-trip-properly', { 
        'one!' => "one!",
        'one!!' => "one!!"
      }

      it 'fails if passing a value' do
        expect {
          described_class.new.parse('one!val')
        }.to raise_error(Parslet::ParseFailed)
        expect {
          described_class.new.parse('one!!val')
        }.to raise_error(Parslet::ParseFailed)
      end 
    end

    context 'csv values result in multiple values for the operation' do
      it_behaves_like 'round-trip-properly', { 
        'multi=1,2' => "multi=[1,2]",
        'multi=1,2,valuehere' => "multi=[1,2,valuehere]"
      }
    end

    context 'supports [a-zA-Z0-9_\.] for filter names' do
      it_behaves_like 'round-trip-properly', { 
        'normal=1'      => 'normal=1',
        'cOmBo=1'       => 'cOmBo=1',
        '1=2'           => '1=2',
        'aFew42Things=1' => 'aFew42Things=1',
        'under_scores=1' => 'under_scores=1',
        'several.dots.in.here=1' => 'several.dots.in.here=1',
        'cOrN.00copia.of_thinGs.42_here=1' => 'cOrN.00copia.of_thinGs.42_here=1',
      }
    end
    context 'supports everything (except &|(),) for values' do
      it_behaves_like 'round-trip-properly', {
        'v=1123' => 'v=1123',
        'v=*foo*' => 'v=*foo*',
        'v=*^%$#@!foo' => 'v=*^%$#@!foo',
        'v=_-+=\{}"?:><' => 'v=_-+=\{}"?:><',
        'v=_-+=\{}"?:><,another_value!' => 'v=[_-+=\{}"?:><,another_value!]',
      }
    end
  end
end