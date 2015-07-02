require 'spec_helper'

describe Praxis::Handlers::XML do

  describe '#parse' do
    shared_examples 'xml something' do
      it 'works' do
        expect(subject.parse(parsed.to_xml)).to eq(parsed)
      end
    end

    #  XML_TYPE_NAMES = {
    #    "Symbol"     => "symbol",
    #    "Fixnum"     => "integer",
    #    "Bignum"     => "integer",
    #    "BigDecimal" => "decimal",
    #    "Float"      => "float",
    #    "TrueClass"  => "boolean",
    #    "FalseClass" => "boolean",
    #    "Date"       => "date",
    #    "DateTime"   => "dateTime",
    #    "Time"       => "dateTime"
    #  }

    context "Parsing symbols" do
      let(:xml){ '<objects type="array"><object type="symbol">a_symbol</object></objects>' }
      let(:parsed){ [:a_symbol] }
      it_behaves_like 'xml something'
    end

    context "Parsing integers" do
      let(:xml){ '<objects type="array"><object type="integer">1234</object></objects>' }
      let(:parsed){ [1234] }
      it_behaves_like 'xml something'
    end

    context "Parsing decimals" do
      let(:xml){ '<objects type="array"><object type="decimal">0.1</object></objects>' }
      let(:parsed){ [0.1] }
      it_behaves_like 'xml something'
    end

    context "Parsing floats" do
      let(:xml){ '<objects type="array"><object type="float">0.1</object></objects>' }
      let(:parsed){ [0.1] }
      it_behaves_like 'xml something'
    end

    context "Parsing booleans" do
      context "that are true" do
        let(:xml){ '<objects type="array"><object type="boolean">true</object></objects>' }
        let(:parsed){ [true] }
        it_behaves_like 'xml something'
      end
      context "that are false" do
        let(:xml){ '<objects type="array"><object type="boolean">false</object></objects>' }
        let(:parsed){ [false] }
        it_behaves_like 'xml something'

      end
    end

    context "Parsing dates" do
      let(:xml){ '<objects type="array"><object type="date">2001-01-01</object></objects>' }
      let(:parsed){ [Date.parse("2001-01-01")] }
      it_behaves_like 'xml something'
    end

    context "Parsing dateTimes" do
      let(:xml){ '<objects type="array"><object type="dateTime">2015-03-13T19:34:40-07:00</object></objects>' }
      let(:parsed){ [DateTime.parse("2015-03-13T19:34:40-07:00")] }
      it_behaves_like 'xml something'
    end

    context "Parsing hashes" do
      context "that are empty" do
        let(:xml){ "<hash></hash>" }

        it 'get converted to empty strings' do
          expect(subject.parse(xml)).to eq('')
        end
      end

      context "with a couple of elements" do
        let(:xml){ '<hash><one type="integer">1</one><two type="integer">2</two></hash>' }
        let(:parsed){ {"one"=>1, "two"=>2} }
        it_behaves_like 'xml something'
      end
      context "with hyphenated elements" do
        let(:xml){ '<hash><part-one type="integer">1</part-one><part-two type="integer">2</part-two></hash>' }
        let(:parsed){ {"part_one"=>1, "part_two"=>2} }
        it_behaves_like 'xml something'
      end
      context "with a nested hash" do
        let(:xml){ '<hash><one type="integer">1</one><sub_hash><first>hello</first></sub_hash></hash>' }
        let(:parsed){ {"one"=>1, "sub_hash"=>{"first"=>"hello"} } }
        it_behaves_like 'xml something'
      end
      context "with a nested array" do
        let(:xml){ '<hash><one type="integer">1</one><two type="array"><object>just text</object></two></hash>' }
        let(:parsed){ {"one"=>1, "two" => ["just text"] } }
        it_behaves_like 'xml something'
      end

    end

    context "Parsing an Array" do
      context 'with a couple of simple elements in it' do
        let(:xml){ '<objects type="array"><object>just text</object><object type="integer">1</object></objects>' }
        let(:parsed){ ["just text", 1] }
        it_behaves_like 'xml something'
      end
      context "with a nested hash" do
        let(:xml){ '<objects type="array"><object>just text</object><object><one type="integer">1</one></object></objects>' }
        let(:parsed){ ["just text", { "one" => 1}] }
        it_behaves_like 'xml something'
      end
    end

    context "Parsing XML strings created with .to_xml" do
      let(:xml){ parsed.to_xml }
      context 'array with a couple of simple elements in it' do
        let(:parsed){ ["just text", 1] }
        it_behaves_like 'xml something'
      end
      context 'a hash with a couple of simple elements in it' do
        let(:parsed){ { "one"=>"just text", "two"=> 1 } }
        it_behaves_like 'xml something'
      end
      context 'a array with elements of all types' do
        let(:parsed){ ["just text",:a,1,BigDecimal.new(100),0.1,true,Date.new] }
        it_behaves_like 'xml something'
      end
      context 'a hash with a complex substructure' do
        let(:parsed) do
          Hash(
            "text" => "just text",
            "symbol" => :a,
            "num" => 1,
            "bd" => BigDecimal.new(100),
            "float" => 0.1,
            "truthyness" => true,
            "day" => Date.new,
            "empty_string" => ""
          )
        end
        it_behaves_like 'xml something'
      end

      context "transformed characters when using .to_xml" do
        context 'underscores become dashes' do
          let(:xml){ {"one_thing"=>1, "two_things"=>2}.to_xml  }
          it do
            doc = Nokogiri::XML(xml)

            expect(doc.search('one-thing')).to_not be_empty
            expect(doc.search('two-things')).to_not be_empty
          end
        end
        context 'spaces become dashes' do
          let(:xml){ {"one thing"=>1, "two things"=>2}.to_xml  }
          let(:parsed){ {"one-thing"=>1, "two-things"=>2} }
          it do
            doc = Nokogiri::XML(xml)

            expect(doc.search('one-thing')).to_not be_empty
            expect(doc.search('two-things')).to_not be_empty
          end
        end
      end
    end

    describe '#generate' do
      it 'has tests'
    end
  end
end
