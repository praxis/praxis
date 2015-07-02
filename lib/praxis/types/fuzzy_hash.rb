module Praxis
  module Types

    class FuzzyHash
      def initialize(value={})
        @hash = {}
        @regexes = []
        update(value)
      end

      def update(value)
        value.each do |k,v|
          self[k] = v
        end

        self
      end

      def []=(k,v)
        case k
        when Regexp
          @regexes << k
        end
        @hash[k] = v
      end

      def [](k)
        return @hash[k] if @hash.key?(k)

        k = k.to_s
        @regexes.each do |regex|
          return @hash[regex] if regex.match(k)
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
