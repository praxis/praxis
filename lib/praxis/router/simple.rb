# frozen_string_literal: true

# Originally from:
# https://github.com/rkh/mustermann/blob/500a603fffe0594ab842d72addcc449eedd6d5be/mustermann/lib/mustermann/router/simple.rb
# Copied here after its removal from Mustermann proper

require 'mustermann'

module Mustermann
  module Router
    # Simple pattern based router that allows matching a string to a given callback.
    #
    # @example
    #   require 'mustermann/router/simple'
    #
    #   router = Mustermann::Router::Simple.new do
    #     on ':name/:sub' do |string, params|
    #       params['sub']
    #     end
    #
    #     on 'foo' do
    #       "bar"
    #     end
    #   end
    #
    #   router.call("foo") # => "bar"
    #   router.call("a/b") # => "b"
    #   router.call("bar") # => nil
    class Simple
      # Default value for when no pattern matches
      attr_accessor :default

      # @example with a default value
      #   require 'mustermann/router/simple'
      #
      #   router = Mustermann::Router::Simple.new(default: 42)
      #   router.on(':name', capture: :digit) { |string| string.to_i }
      #   router.call("23")      # => 23
      #   router.call("example") # => 42
      #
      # @example block with implicit receiver
      #   require 'mustermann/router/simple'
      #
      #   router = Mustermann::Router::Simple.new do
      #     on('/foo') { 'foo' }
      #     on('/bar') { 'bar' }
      #   end
      #
      # @example block with explicit receiver
      #   require 'mustermann/router/simple'
      #
      #   router = Mustermann::Router::Simple.new(type: :rails) do |r|
      #     r.on('/foo') { 'foo' }
      #     r.on('/bar') { 'bar' }
      #   end
      #
      # @param default value to be returned if nothing matches
      # @param options [Hash] pattern options
      # @return [Mustermann::Router::Simple] new router instance
      def initialize(default: nil, **options, &block)
        @options = options
        @map     = []
        @default = default

        return unless block

        block.arity.zero? ? instance_eval(&block) : yield(self)
      end

      # @example
      #   require 'mustermann/router/simple'
      #
      #   router = Mustermann::Router::Simple.new
      #   router.on(':a/:b') { 42 }
      #   router['foo/bar'] # => <#Proc:...>
      #   router['foo_bar'] # => nil
      #
      # @return [#call, nil] callback for given string, if a pattern matches
      def [](string)
        string = string_for(string) unless string.is_a? String
        @map.detect { |p, _v| p === string }[1] # rubocop:disable Style/CaseEquality
      end

      # @example
      #   require 'mustermann/router/simple'
      #
      #   router = Mustermann::Router::Simple.new
      #   router['/:name'] = proc { |string, params| params['name'] }
      #   router.call('/foo') # => "foo"
      #
      # @param pattern [String, Mustermann::Pattern] matcher
      # @param callback [#call] callback to call on match
      # @see #on
      def []=(pattern, callback)
        on(pattern, call: callback)
      end

      # @example with block
      #   require 'mustermann/router/simple'
      #
      #   router = Mustermann::Router::Simple.new
      #
      #   router.on(':a/:b') { 42 }
      #   router.call('foo/bar') # => 42
      #   router.call('foo_bar') # => nil
      #
      # @example with callback option
      #   require 'mustermann/router/simple'
      #
      #   callback = proc { 42 }
      #   router   = Mustermann::Router::Simple.new
      #
      #   router.on(':a/:b', call: callback)
      #   router.call('foo/bar') # => 42
      #   router.call('foo_bar') # => nil
      #
      # @param patterns [Array<String, Pattern>]
      # @param call [#call] callback object, need to hand in block if missing
      # @param options [Hash] pattern options
      def on(*patterns, call: Proc.new, **options)
        patterns.each do |pattern|
          pattern = Mustermann.new(pattern.to_str, **options, **@options) if pattern.respond_to? :to_str
          @map << [pattern, call]
        end
      end

      # Finds the matching callback and calls `call` on it with the given input and the params.
      # @return the callback's return value
      def call(input)
        @map.each do |pattern, callback|
          catch(:pass) do
            next unless (params = pattern.params(string_for(input)))

            return invoke(callback, input, params, pattern)
          end
        end
        @default
      end

      def invoke(callback, input, params, _pattern)
        callback.call(input, params)
      end

      def string_for(input)
        input.to_str
      end

      private :invoke, :string_for
    end
  end
end
