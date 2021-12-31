# frozen_string_literal: true

require 'parslet'

module Praxis
  module Extensions
    module AttributeFiltering
      class FilteringParams
        class Condition
          attr_reader :name, :op, :values
          attr_accessor :parent_group

          # For operands with a single or no values: Incoming data is a hash with name and op
          # For Operands with multiple values: Incoming data is an array of hashes
          #   First hash has the spec (i.e., name and op)
          #   The rest of the hashes contain a value each (a hash with value: X each).
          #   Example: [{:name=>"multi"@0, :op=>"="@5}, {:value=>"1"@6}, {:value=>"2"@8}]
          def initialize(triad:, parent_group:)
            @parent_group = parent_group
            if triad.is_a? Array # several values coming in
              spec, *values = triad
              @name = spec[:name].to_sym
              @op = spec[:op].to_s

              if values.empty?
                @values = ''
                @fuzzies = nil
              elsif values.size == 1
                raw_val = values.first[:value].to_s
                @values, @fuzzies = _compute_fuzzy(values.first[:value].to_s)
              else
                @values = []
                @fuzzies = []
                results = values.each do |e|
                  val, fuz = _compute_fuzzy(e[:value].to_s)
                  @values.push val
                  @fuzzies.push fuz
                end
              end
            else # No values for the operand
              @name = triad[:name].to_sym
              @op = triad[:op].to_s
              if ['!', '!!'].include?(@op)
                @values = nil
                @fuzzies = nil
              else
                # Value operand without value? => convert it to empty string
                raise "Interesting, didn't know this could happen. Oops!" if triad[:value].is_a?(Array) && !triad[:value].empty?

                if triad[:value] == []
                  @values = ''
                  @fuzzies = nil
                else
                  @values, @fuzzies = _compute_fuzzy(triad[:value].to_s)
                end
              end
            end
          end

          # Takes a raw val, and spits out the output val (unescaped), and the fuzzy definition
          def _compute_fuzzy(raw_val)
            starting = raw_val[0] == '*'
            ending = raw_val[-1] == '*'
            newval, fuzzy = if starting && ending
                              [raw_val[1..-2], :start_end]
                            elsif starting
                              [raw_val[1..-1], :start]
                            elsif ending
                              [raw_val[0..-2], :end]
                            else
                              [raw_val, nil]
                            end
            newval = CGI.unescape(newval) if newval
            [newval, fuzzy]
          end

          def flattened_conditions
            [{ name: @name, op: @op, values: @values, fuzzies: @fuzzies, node_object: self }]
          end

          # Dumps the value, marking where the fuzzy might be, and removing the * to differentiate from literals
          def _dump_value(val, fuzzy)
            case fuzzy
            when nil
              val
            when :start_end
              "{*}#{val}{*}"
            when :start
              "{*}#{val}"
            when :end
              "#{val}{*}"
            end
          end

          def dump
            vals = if values.is_a? Array
                     dumped = values.map.with_index { |val, i| _dump_value(val, @fuzzies[i]) }
                     "[#{dumped.join(',')}]" # Purposedly enclose in brackets to make sure we differentiate
                   else
                     values == '' ? '""' : _dump_value(values, @fuzzies) # Dump the empty string explicitly with quotes if we've converted no value to empty string
                   end
            "#{name}#{op}#{vals}"
          end
        end

        # An Object that represents an AST tree for either an OR or an AND conditions
        # to be applied to its items children
        class ConditionGroup
          attr_reader :items, :type
          attr_accessor :parent_group, :associated_query # Metadata to be used by whomever is manipulating this

          def self.load(node)
            if node[:o]
              compactedl = compress_tree(node: node[:l], op: node[:o])
              compactedr = compress_tree(node: node[:r], op: node[:o])
              compacted = { op: node[:o], items: compactedl + compactedr }

              loaded = ConditionGroup.new(**compacted, parent_group: nil)
            else
              loaded = Condition.new(triad: node[:triad], parent_group: nil)
            end
            loaded
          end

          def initialize(op:, items:, parent_group:)
            @type = op.to_s == '&' ? :and : :or
            @items = items.map do |item|
              if item[:op]
                ConditionGroup.new(**item, parent_group: self)
              else
                Condition.new(triad: item[:triad], parent_group: self)
              end
            end
            @parent_group = parent_group
          end

          def dump
            "( #{@items.map(&:dump).join(" #{type.upcase} ")} )"
          end

          # Returns an array with flat conditions from all child triad conditions
          def flattened_conditions
            @items.inject([]) do |accum, item|
              accum + item.flattened_conditions
            end
          end

          # Given a binary tree of operand conditions, transform it to a multi-leaf tree
          # where a single condition node has potentially multiple subtrees for the same operation (instead of 2)
          # For example (&, (&, a, b), (|, c, d)) => (&, a, b, (|, c, d))
          def self.compress_tree(node:, op:)
            return [node] if node[:triad]

            # It is an op node
            if node[:o] == op
              # compatible op as parent, collect my compacted children and return them up skipping my op
              resultl = compress_tree(node: node[:l], op: op)
              resultr = compress_tree(node: node[:r], op: op)
              resultl + resultr
            else
              collected = compress_tree(node: node, op: node[:o])
              [{ op: node[:o], items: collected }]
            end
          end
        end

        class Parser < Parslet::Parser
          root :expression
          rule(:lparen)     { str('(') }
          rule(:rparen)     { str(')') }
          rule(:comma) { str(',') }
          rule(:val_operator) { str('!=') | str('>=') | str('<=') | str('=') | str('<') | str('>') }
          rule(:noval_operator) { str('!!') | str('!') }
          rule(:and_kw) { str('&') }
          rule(:or_kw) { str('|') }

          def infix(*args)
            Infix.new(*args)
          end

          rule(:name)    { match('[a-zA-Z0-9_\.]').repeat(1) } # TODO: are these the only characters that we allow for names?
          rule(:chars) { match('[^&|(),]').repeat(0).as(:value) }
          rule(:value) { chars >> (comma >> chars).repeat }

          rule(:triad) do
            (name.as(:name) >> val_operator.as(:op) >> value).as(:triad) |
              (name.as(:name) >> noval_operator.as(:op)).as(:triad) |
              lparen >> expression >> rparen
          end

          rule(:expression) do
            infix_expression(triad, [and_kw, 2, :left], [or_kw, 1, :right])
          end
        end
      end
    end
  end
end
