# frozen_string_literal: true

require 'spec_helper'

describe Praxis::Extensions::FieldSelection::ActiveRecordQuerySelector do
  let(:selector_fields) do
    {
      name: true,
      author: {
        id: true,
        books: true,
      },
      category: {
        name: true,
        books: true,
      },
      tags: {
        name: true,
      },
    }
  end
  let(:expected_select_from_to_query) do
    # The columns to select from the top Simple model
    [
      :id, # We always load the primary keys
      :simple_name, # from the :name alias
      :author_id, # the FK needed for the author association
      :added_column, # from the extra column defined in the parent property
      :category_uuid, # the FK needed for the cateory association
    ]
  end
  let(:selector_node) do
    Praxis::Mapper::SelectorGenerator
      .new
      .add(ActiveBookResource, selector_fields)
      .selectors
  end
  let(:debug) { false }

  subject(:selector) do
    described_class.new(query: query, selectors: selector_node, debug: debug)
  end

  context '#generate' do
    context 'with a mock model' do
      let(:query) { double('Query') }
      it 'calls the select columns for the top level, and includes the right association hashes' do
        expect(query).to receive(:select).with(
          *expected_select_from_to_query,
        ).and_return(query)
        expected_includes = {
          author: {
            books: {
            },
          },
          category: {
            books: {
            },
          },
          tags: {
          },
        }
        expect(query).to receive(:includes).with(expected_includes).and_return(
          query,
        )
        expect(subject).to_not receive(:explain_query)
        subject.generate
      end
      context 'when debug is enabled' do
        let(:debug) { true }
        it 'calls the explain method' do
          expect(query).to receive(:select).and_return(query)
          expect(query).to receive(:includes).and_return(query)
          expect(subject).to receive(:explain_query)
          subject.generate
        end
      end
    end

    context 'with a real AR model' do
      let(:query) { ActiveBook }

      it 'calls the select columns for the top level, and includes the right association hashes' do
        expected_includes = {
          author: {
            books: {
            },
          },
          category: {
            books: {
            },
          },
          tags: {
          },
        }
        # expect(query).to receive(:includes).with(expected_includes).and_return(query)
        expect(subject).to_not receive(:explain_query)
        final_query = subject.generate
        expect(final_query.select_values).to match_array(
          expected_select_from_to_query,
        )
        # Our query selector always uses a single hash tree from the top, not an array of things
        includes_hash = final_query.includes_values.first
        expect(includes_hash).to match(expected_includes)
        # Also, make AR do the actual query to make sure everything is wired up correctly
        result = final_query.to_a
        expect(result.size).to be > 2 # We are using 2 but we've seeded more
        book1 = result[0]
        book2 = result[1]
        expect(book1.author.id).to eq 11
        expect(book1.author.books.size).to eq 1
        expect(book1.author.books.map(&:simple_name)).to eq(['Book1'])
        expect(book1.category.name).to eq 'cat1'
        expect(book1.tags.map(&:name)).to match_array(%w[blue red green])

        expect(book2.author.id).to eq 22
        expect(book2.author.books.size).to eq 1
        expect(book2.author.books.map(&:simple_name)).to eq(['Book2'])
        expect(book2.category.name).to eq 'cat2'
        expect(book2.tags.map(&:name)).to match_array(['red'])
      end

      it 'calls the explain debug method if enabled' do
        suppress_output do
          # Actually make it run all the way...but suppressing the output
          subject.generate
        end
      end

      context 'and fields that contain transitive dependencies on the root model' do
        let(:selector_fields) { { author: { books: { isbn: true } } } }
        let(:expected_select_from_to_query) do
          # The columns to select from the top Simple model
          [
            :id, # We always load the primary keys
            :isbn, # from the transitive author.books.isbn
            :author_id, # the FK needed for the author association
            :added_column, # from the extra column defined in the parent property
          ]
        end
        it 'hoists transitive columns to the root' do
          final_query = subject.generate
          expect(final_query.select_values).to match_array(
            expected_select_from_to_query,
          )
        end
      end
    end
  end
end
