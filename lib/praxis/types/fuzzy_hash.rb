# frozen_string_literal: true

module Praxis
  module Types
    class FuzzyHash
      def initialize(value = {})
        @hash = {}
        @regexes = []
        update(value)
      end

      def update(value)
        value.each do |key, val|
          self[key] = val
        end

        self
      end

      def []=(key, val)
        case key
        when Regexp
          @regexes << key
        end
        @hash[key] = val
      end

      def [](key)
        return @hash[key] if @hash.key?(key)

        key = key.to_s
        @regexes.each do |regex|
          return @hash[regex] if regex.match(key)
        end

        nil
      end

      def method_missing(*args, &block)
        @hash.send(*args, &block)
      end

      def respond_to_missing?(*args)
        @hash.respond_to?(*args)
      end
    end
  end
end
