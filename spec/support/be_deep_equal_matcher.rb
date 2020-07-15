# Copied verbatim from: https://github.com/amogil/rspec-deep-ignore-order-matcher

RSpec::Matchers.define :be_deep_equal do |expected|
  match { |actual| match? actual, expected }

  failure_message do |actual|
    "expected that #{actual} would be deep equal with #{expected}"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not be deep equal with #{expected}"
  end

  description do
    "be deep equal with #{expected}"
  end

  def match?(actual, expected)
    return arrays_match?(actual, expected) if expected.is_a?(Array) && actual.is_a?(Array)
    return hashes_match?(actual, expected) if expected.is_a?(Hash) && actual.is_a?(Hash)
    expected == actual
  end

  def arrays_match?(actual, expected)
    exp = expected.clone
    actual.each do |a|
      index = exp.find_index { |e| match? a, e }
      return false if index.nil?
      exp.delete_at(index)
    end
    exp.empty?
  end

  def hashes_match?(actual, expected)
    return false unless actual.keys.sort == expected.keys.sort
    actual.each { |key, value| return false unless match? value, expected[key] }
    true
  end
end
