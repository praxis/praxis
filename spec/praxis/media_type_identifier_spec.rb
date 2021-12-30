# frozen_string_literal: true

# rubocop:disable Style/StringConcatenation

require 'spec_helper'

describe Praxis::MediaTypeIdentifier do
  let(:example) { 'application/ice-cream+sundae; nuts="true"; fudge="true"' }

  subject { described_class.load(example) }

  context '.load' do
    context 'of nil values' do
      let(:example) { nil }
      it 'return nil' do
        expect(subject).to be(nil)
      end
    end

    context 'of empty string values' do
      let(:example) { '' }
      it 'returns nil' do
        expect(subject).to be(nil)
      end
    end

    it 'parses type/subtype' do
      expect(subject.type).to eq('application')
      expect(subject.subtype).to eq('ice-cream')
    end

    it 'parses suffix' do
      expect(subject.suffix).to eq('sundae')
    end

    context 'given parameters' do
      let(:example) { 'application/vnd.widget; encoding="martian"' }
      let(:unquoted_example) { 'application/vnd.widget; encoding=martian' }
      let(:tricky_example) { 'application/vnd.widget; sauce="yes; absolutely"' }

      it 'handles quoted values' do
        expect(described_class.new(example).parameters['encoding']).to eq('martian')
      end

      it 'handles unquoted values' do
        expect(described_class.new(unquoted_example).parameters['encoding']).to eq('martian')
      end

      # TODO: Maybe that's something we want to support in the future? seems a big hammer for such a thing
      # it 'handles quoted semicolons in values' do
      #   pending("need to stop using a regexp to do a context-free parser's job")
      #   expect(described_class.new(tricky_example).parameters['sauce']).to eq('yes; absolutely')
      # end
    end

    context 'given a malformed type' do
      it 'tolerates extra slash or plus' do
        ['man/bear/pig', 'c/c++', 'application/ice-cream+cone+dipped'].each do |eg|
          expect(described_class.new(eg).to_s).to eq(eg)
        end
      end

      it 'assumes application/XYZ' do
        ['nachos', 'tacos with extra cheese!'].each do |eg|
          prefix = eg.split(/\s+/).first
          expect(described_class.new(eg).to_s).to eq("application/#{prefix}")
        end
      end
    end
  end

  context '#match' do
    subject { described_class }

    # @example match anything
    #      MediaTypeIdentifier.load('*/*').match('application/icecream+cone; flavor=vanilla') # => true
    #
    # @example match a subtype wildcard
    #      MediaTypeIdentifier.load('image/*').match('image/jpeg') # => true
    #
    # @example match a specific type irrespective of structured syntax
    #      MediaTypeIdentifier.load('application/vnd.widget').match('application/vnd.widget+json') # => true
    #
    # @example match a specific type, respective of important parameters but irrespective of extra parameters or structured syntax
    #      MediaTypeIdentifier.load('application/vnd.widget; type=collection').match('application/vnd.widget+json; material=steel; type=collection') # => true

    it 'accepts String' do
      expect(subject.new('image/jpeg').match('image/jpeg')).to be_truthy
      expect(subject.new('image/jpeg').match('image/png')).to be_falsey
    end

    it 'accepts MediaTypeIdentifier' do
      expect(subject.new('image/jpeg').match(subject.new('image/jpeg'))).to be_truthy
      expect(subject.new('image/jpeg').match(subject.new('image/png'))).to be_falsey
    end

    it 'understands type wildcards' do
      expect(subject.new('*/*').match('application/pizza')).to be_truthy
    end

    it 'understands subtype wildcards' do
      expect(subject.new('application/*').match('application/pizza')).to be_truthy
      expect(subject.new('application/*').match('image/jpeg')).to be_falsey
    end

    it 'understands structured-syntax suffixes' do
      expect(subject.new('application/vnd.widget').match('application/vnd.widget+json')).to be_truthy
      expect(subject.new('application/vnd.widget+json').match('application/vnd.widget+xml')).to be_falsey
    end

    it 'understands parameters' do
      expect(subject.new('application/vnd.widget; type=collection').match('application/vnd.widget; type=collection; material=steel')).to be_truthy
      expect(subject.new('application/vnd.widget+json; material=steel').match('application/vnd.widget+xml; material=copper')).to be_falsey
    end
  end

  context '#=~' do
    subject { described_class.new('image/jpeg') }
    it 'delegates to #match' do
      expect(subject).to receive(:match).once
      (described_class.new('image/jpeg') =~ subject)
    end
  end

  context '#==' do
    let(:example) { 'application/vnd.widget+xml; charset=UTF8' }
    subject { described_class }

    it 'compares all attributes' do
      expect(subject.new('application/json')).not_to eq(subject.new('application/xml'))
      expect(subject.new('application/vnd.widget+json')).not_to eq(subject.new('application/vnd.widget+xml'))
      expect(subject.new('text/plain; charset=UTF8')).not_to eq(subject.new('text/plain; charset=martian'))

      expect(subject.new(example)).to eq(subject.new(example))
    end

    it 'ignores parameter ordering' do
      expect(subject.new('text/plain; a=1; b=2')).to eq(subject.new('text/plain; b=2; a=1'))
    end
  end

  context '#to_s' do
    subject { described_class.new(example) }

    it 'includes type/subtype' do
      expect(subject.to_s).to start_with('application/ice-cream')
    end

    it 'includes suffix' do
      expect(subject.to_s).to start_with('application/ice-cream+sundae')
    end

    it 'canonicalizes parameter ordering' do
      expect(subject.to_s).to end_with('; fudge=true; nuts=true')
    end
  end

  context '#without_parameters' do
    it 'excludes parameters' do
      expect(subject.without_parameters.to_s).to eq('application/ice-cream+sundae')
    end
  end

  context '#handler_name' do
    subject { described_class }

    let(:with_suffix) { 'application/vnd.widget+xml' }
    let(:with_subtype) { 'text/xml' }
    let(:with_both) { 'text/json+xml' } # nonsensical but valid!

    it 'uses the suffix' do
      expect(subject.new(with_suffix).handler_name).to eq('xml')
    end

    it 'uses the subtype' do
      expect(subject.new(with_subtype).handler_name).to eq('xml')
    end

    it 'prefers the suffix' do
      expect(subject.new(with_both).handler_name).to eq('xml')
    end
  end

  context '#+' do
    let(:simple_subject) { described_class.new('application/vnd.icecream') }
    let(:complex_subject) { described_class.new('application/vnd.icecream+json; nuts="true"') }

    it 'adds a suffix' do
      expect(simple_subject + 'xml').to \
        eq(described_class.new('application/vnd.icecream+xml'))
      expect(simple_subject + '+xml').to \
        eq(described_class.new('application/vnd.icecream+xml'))
    end

    it 'adds parameters' do
      expect(simple_subject + 'nuts=true').to \
        eq(described_class.new('application/vnd.icecream; nuts=true'))

      expect(simple_subject + '; nuts=true').to \
        eq(described_class.new('application/vnd.icecream; nuts=true'))
    end

    it 'adds suffix and parameters' do
      expect(simple_subject + 'xml; nuts=true').to \
        eq(described_class.new('application/vnd.icecream+xml; nuts=true'))
    end

    it 'replaces the suffix' do
      expect(complex_subject + 'xml').to \
        eq(described_class.new('application/vnd.icecream+xml; nuts=true'))
    end

    it 'replaces existing parameters and adds new ones' do
      expect(complex_subject + 'nuts=false; cherry=true').to \
        eq(described_class.new('application/vnd.icecream+json; cherry=true; nuts=false'))

      expect(complex_subject + '; nuts=false; cherry=true').to \
        eq(described_class.new('application/vnd.icecream+json; cherry=true; nuts=false'))
    end

    it 'replaces suffix and parameters and adds new ones' do
      expect(complex_subject + 'json; nuts=false; cherry=true').to \
        eq(described_class.new('application/vnd.icecream+json; cherry=true; nuts=false'))
    end

    context 'does not add json for an already json identifier' do
      it 'non-parameterized mediatypes simply ignore adding the suffix' do
        plain_application_json = described_class.new('application/json')

        expect(plain_application_json + 'json').to \
          eq(plain_application_json)
      end
      it 'parameterized mediatypes still keeps them' do
        parameterized_application_json = described_class.new('application/json; cherry=true; nuts=false')
        expect(parameterized_application_json + 'json').to \
          eq(parameterized_application_json)
      end
    end
  end
end
# rubocop:enable Style/StringConcatenation
