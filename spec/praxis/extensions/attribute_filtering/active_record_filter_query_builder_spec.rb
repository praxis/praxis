require 'spec_helper'

require_relative '../support/spec_resources_active_model.rb'
require 'praxis/extensions/attribute_filtering'
require 'praxis/extensions/attribute_filtering/active_record_filter_query_builder'

describe Praxis::Extensions::AttributeFiltering::ActiveRecordFilterQueryBuilder do
  let(:root_resource) { ActiveBookResource }
  let(:filters_map) { root_resource.instance_variable_get(:@_filters_map)}
  let(:base_model) { root_resource.model }
  let(:base_query) { base_model }
  let(:instance) { described_class.new(query: base_query, model: base_model, filters_map: filters_map) }

  shared_examples 'subject_equivalent_to' do |expected_result|
    it do
      loaded_ids = subject.all.map(&:id).sort
      expected_ids = expected_result.all.map(&:id).sort
      expect(loaded_ids).to_not be_empty
      expect(loaded_ids).to eq(expected_ids)
    end
  end

  # Poorman's way to compare SQL queries...
  shared_examples 'subject_matches_sql' do |expected_sql|
    it do
       # Remove parenthesis as our queries have WHERE clauses using them...
      gen_sql = subject.all.to_sql.gsub(/[()]/,'')
      # Strip blank at the beggining (and end) of every line
      # ...and recompose it by adding an extra space at the beginning of each one instead
      exp = expected_sql.split(/\n/).map do |line|
        " " + line.strip.gsub(/[()]/,'')
      end.join.strip
      expect(gen_sql).to eq(exp)
    end
  end

  context 'initialize' do
    it 'sets the right things to the instance' do
      instance
      expect(instance.query).to eq(base_query)
      expect(instance.model).to eq(base_model)
      expect(instance.attr_to_column).to eq(filters_map)
    end
  end
  context 'build_clause' do
    subject { instance.build_clause(filters) }
    let(:filters) { Praxis::Types::FilteringParams.load(filters_string)}

    context 'with no filters' do
      let(:filters_string) { '' }
      it 'does not modify the query' do
        expect(subject).to be(base_query)
      end
    end
    context 'by a simple field' do
      context 'that maps to the same name' do
        let(:filters_string) { 'category_uuid=deadbeef1' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1')
      end
      context 'that maps to a different name' do
        let(:filters_string) { 'name=Book1'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(simple_name: 'Book1')
      end
      context 'that is mapped as a nested struct' do
        let(:filters_string) { 'fake_nested.name=Book1'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(simple_name: 'Book1')
      end
    end

    context 'by a field or a related model' do
      context 'for a belongs_to association' do
        let(:filters_string) { 'author.name=author2'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name' => 'author2')
      end
      context 'for a has_many association' do
        let(:filters_string) { 'taggings.label=primary' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:taggings).where('active_taggings.label' => 'primary')
      end
      context 'for a has_many through association' do
        let(:filters_string) { 'tags.name=blue' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:tags).where('active_tags.name' => 'blue')
      end
    end

    context 'by using all supported operators' do
      PREF = Praxis::Extensions::AttributeFiltering::ALIAS_TABLE_PREFIX
      COMMON_SQL_PREFIX = <<~SQL
            SELECT "active_books".* FROM "active_books"
            INNER JOIN
              "active_authors" "#{PREF}/author" ON "#{PREF}/author"."id" = "active_books"."author_id"
          SQL
      context '=' do
        let(:filters_string) { 'author.id=11'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id = 11')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."id" = 11
          SQL
      end
      context '= (with array)' do
        let(:filters_string) { 'author.id=11,22'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id IN (11,22)')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."id" IN (11,22)
          SQL
      end      
      context '!=' do
        let(:filters_string) { 'author.id!=11'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id <> 11')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."id" <> 11
          SQL
      end
      context '!= (with array)' do
        let(:filters_string) { 'author.id!=11,888'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id NOT IN (11,888)')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."id" NOT IN (11,888)
          SQL
      end
      context '>' do
        let(:filters_string) { 'author.id>1'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id > 1')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."id" > 1
          SQL
      end
      context '<' do
        let(:filters_string) { 'author.id<22'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id < 22')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."id" < 22
          SQL
      end
      context '>=' do
        let(:filters_string) { 'author.id>=22'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id >= 22')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."id" >= 22
          SQL
      end
      context '<=' do
        let(:filters_string) { 'author.id<=22'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id <= 22')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."id" <= 22
          SQL
      end
      context '!' do
        let(:filters_string) { 'author.id!'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id IS NOT NULL')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."id" IS NOT NULL
          SQL
      end
      context '!!' do
        let(:filters_string) { 'author.name!!'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name IS NULL')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."name" IS NULL
          SQL
      end      
      context 'including LIKE fuzzy queries' do
        context 'LIKE' do
          let(:filters_string) { 'author.name=author*'}
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name LIKE "author%"')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."name" LIKE 'author%'
          SQL
        end
        context 'NOT LIKE' do
          let(:filters_string) { 'author.name!=foobar*'}
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name NOT LIKE "foobar%"')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "#{PREF}/author"."name" NOT LIKE 'foobar%'
          SQL
        end
      end
    end

    context 'with a field mapping using a proc' do
      let(:filters_string) { 'name_is_not=Book1' }
      it_behaves_like 'subject_equivalent_to', ActiveBook.where.not(simple_name: 'Book1')
    end

    context 'with a deeply nested chains' do
      context 'of depth 2' do
        let(:filters_string) { 'category.books.name=Book2' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(category: :books).where('books_active_categories.simple_name': 'Book2')
      end
      context 'multiple conditions on a nested relationship' do
        let(:filters_string) { 'category.books.taggings.tag_id=1&category.books.taggings.label=primary' }
        it_behaves_like 'subject_equivalent_to', 
          ActiveBook.joins(category: { books: :taggings }).where('active_taggings.tag_id': 1).where('active_taggings.label': 'primary')
        it_behaves_like 'subject_matches_sql', <<~SQL
            SELECT "active_books".* FROM "active_books"
              INNER JOIN "active_categories" ON "active_categories"."uuid" = "active_books"."category_uuid"
              INNER JOIN "active_books" "books_active_categories" ON "books_active_categories"."category_uuid" = "active_categories"."uuid"
              INNER JOIN "active_taggings" "#{PREF}/category/books/taggings" ON "/category/books/taggings"."book_id" = "books_active_categories"."id"
              WHERE ("#{PREF}/category/books/taggings"."tag_id" = 1)
              AND ("#{PREF}/category/books/taggings"."label" = 'primary')
          SQL
      end
      context 'that contain multiple joins to the same table' do
        let(:filters_string) { 'taggings.tag.taggings.tag_id=1' }
        it_behaves_like 'subject_equivalent_to', 
          ActiveBook.joins(taggings: {tag: :taggings}).where('taggings_active_tags.tag_id=1')
      end
    end

    context 'by multiple fields' do
      context 'adds the where clauses for the top model if fields belong to it' do
        let(:filters_string) { 'category_uuid=deadbeef1&name=Book1' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1',  simple_name: 'Book1')
      end
      context 'adds multiple where clauses for same nested relationship join (instead of multiple joins with 1 clause each)' do
        let(:filters_string) { 'taggings.label=primary&taggings.tag_id=2' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:taggings).where('active_taggings.label' => 'primary', 'active_taggings.tag_id' => 2)
      end
    end

    context 'uses fully qualified names for conditions (disambiguate fields)' do
      context 'when we have a join table condition that has the same field' do
        COMMON_SQL_PREFIX = <<~SQL
        SELECT "active_books".* FROM "active_books"
          INNER JOIN "active_categories" ON "active_categories"."uuid" = "active_books"."category_uuid"
          INNER JOIN "active_books" "#{PREF}/category/books" ON "#{PREF}/category/books"."category_uuid" = "active_categories"."uuid"    
        SQL
        let(:filters_string) { 'name=Book1&category.books.name=Book3' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(category: :books)
                                                  .where('simple_name': 'Book1')
                                                  .where('books_active_categories.simple_name': 'Book3')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/category/books"."simple_name" = 'Book3')
            AND ("active_books"."simple_name" = 'Book1')
          SQL
      end

      context 'it qualifis them even if there are no joined tables/conditions at all' do
        let(:filters_string) { 'id=11'}
        it_behaves_like 'subject_matches_sql', <<~SQL
          SELECT "active_books".* FROM "active_books"
            WHERE "active_books"."id" = 11
          SQL
      end

    end

    context 'ActiveRecord continues to work as expected (with our patches)' do
      context 'using a deep join with repeated tables' do
        subject{ ActiveBook.joins(taggings: {tag: :taggings}).where('taggings_active_tags.tag_id=1') }
        it 'performs query' do
          expect(subject.to_a).to_not be_empty 
        end
        it_behaves_like 'subject_matches_sql', <<~SQL
          SELECT "active_books".* FROM "active_books"
            INNER JOIN "active_taggings" ON "active_taggings"."book_id" = "active_books"."id"
            INNER JOIN "active_tags" ON "active_tags"."id" = "active_taggings"."tag_id"
            INNER JOIN "active_taggings" "taggings_active_tags" ON "taggings_active_tags"."tag_id" = "active_tags"."id"
            WHERE (taggings_active_tags.tag_id=1)
        SQL
      end
      context 'a deep join with repeated tables with the root AND the join, along with :through joins as well' do
        subject!{ ActiveBook.joins(tags: {books: {taggings: :book}}).where('books_active_taggings.simple_name="Book2"') }
        it 'performs query' do
          expect(subject.to_a).to_not be_empty 
        end
        it_behaves_like 'subject_matches_sql', <<~SQL
          SELECT "active_books".* FROM "active_books" 
               INNER JOIN "active_taggings" ON "active_taggings"."book_id" = "active_books"."id"
               INNER JOIN "active_tags" ON "active_tags"."id" = "active_taggings"."tag_id"
               INNER JOIN "active_taggings" "taggings_active_tags_join" ON "taggings_active_tags_join"."tag_id" = "active_tags"."id" 
               INNER JOIN "active_books" "books_active_tags" ON "books_active_tags"."id" = "taggings_active_tags_join"."book_id" 
               INNER JOIN "active_taggings" "taggings_active_books" ON "taggings_active_books"."book_id" = "books_active_tags"."id" 
               INNER JOIN "active_books" "books_active_taggings" ON "books_active_taggings"."id" = "taggings_active_books"."book_id"
               WHERE (books_active_taggings.simple_name="Book2")             
        SQL
      end
    end

    context 'respects scopes' do
      context 'for a has_many through association' do
        let(:filters_string) { 'primary_tags.name=blue' }
        it_behaves_like 'subject_equivalent_to', 
          ActiveBook.joins(:primary_tags).where('active_tags.name="blue"')

        it 'adds the association scope clause to the join' do
          inner_join_pieces = subject.to_sql.split('INNER')
          found = inner_join_pieces.any? do |line|
            line =~ /\s+JOIN "active_taggings".+ON.+\."label" = 'primary'/
          end
          expect(found).to be_truthy
        end
        # This is slightly incorrect in AR 6.1+ (since the picked aliases for active_taggings tables vary)
        # it_behaves_like 'subject_matches_sql', <<~SQL
        #   SELECT "active_books".* FROM "active_books"
        #     INNER JOIN "active_taggings" ON "active_taggings"."label" = 'primary'
        #                 AND "active_taggings"."book_id" = "active_books"."id"
        #     INNER JOIN "active_tags" "/primary_tags" ON "/primary_tags"."id" = "active_taggings"."tag_id"
        #     WHERE ("/primary_tags"."name" = 'blue')
        # SQL
      end
    end
  end
end
