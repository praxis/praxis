require "spec_helper"

describe Praxis::Types::FuzzyHash do

  let(:initial_value) {{
    'key' => 'value',
    /bob/ => 'rob',
    /\d+/ => 'one'
  }}

  subject(:hash) { Praxis::Types::FuzzyHash.new(initial_value) }

  its(['key']) { should eq 'value' }
  its([/bob/]) { should eq 'rob' }
  its(['bobby']) { should eq 'rob' }
  
  its([1]) { should eq 'one' }
  its(['1']) { should eq 'one' }
end

