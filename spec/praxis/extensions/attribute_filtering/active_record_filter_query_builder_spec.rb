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
      COMMON_SQL_PREFIX = <<~SQL
            SELECT "active_books".* FROM "active_books"
            INNER JOIN 
              "active_authors" as "active_books/author" ON "active_books/author"."id" = "active_books"."author_id"
          SQL
      context '=' do
        let(:filters_string) { 'author.id=11'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id = 11')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."id" = 11
          SQL
      end
      context '= (with array)' do
        let(:filters_string) { 'author.id=11,22'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id IN (11,22)')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."id" IN (11,22)
          SQL
      end      
      context '!=' do
        let(:filters_string) { 'author.id!=11'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id <> 11')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."id" <> 11
          SQL
      end
      context '!= (with array)' do
        let(:filters_string) { 'author.id!=11,888'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id NOT IN (11,888)')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."id" NOT IN (11,888)
          SQL
      end
      context '>' do
        let(:filters_string) { 'author.id>1'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id > 1')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."id" > 1
          SQL
      end
      context '<' do
        let(:filters_string) { 'author.id<22'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id < 22')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."id" < 22
          SQL
      end
      context '>=' do
        let(:filters_string) { 'author.id>=22'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id >= 22')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."id" >= 22
          SQL
      end
      context '<=' do
        let(:filters_string) { 'author.id<=22'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id <= 22')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."id" <= 22
          SQL
      end
      context '!' do
        let(:filters_string) { 'author.id!'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id IS NOT NULL')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."id" IS NOT NULL
          SQL
      end
      context '!!' do
        let(:filters_string) { 'author.name!!'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name IS NULL')
        it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."name" IS NULL
          SQL
      end      
      context 'including LIKE fuzzy queries' do
        context 'LIKE' do
          let(:filters_string) { 'author.name=author*'}
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name LIKE "author%"')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."name" LIKE 'author%'
          SQL
        end
        context 'NOT LIKE' do
          let(:filters_string) { 'author.name!=foobar*'}
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name NOT LIKE "foobar%"')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE "active_books/author"."name" NOT LIKE 'foobar%'
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

    context 'respecting scopes' do
      context 'for a has_many through association' do
        let(:filters_string) { 'primary_tags.name=red' }
        it do
          ActiveRecord::Base.logger = Logger.new(STDOUT)
          ref = ActiveBook.joins(category: { books: :taggings }).all
          atrack = ref.alias_tracker
          ref = ref.joins(:taggings).all          
          atrack2 = ref.alias_tracker
          binding.pry
          ref.to_sql
          ref.to_a
          binding.pry
          ref.alias_candidate
          ref.to_a
          #subject.to_a
          puts "ASdfa"
        end
        #it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:primary_tags).where('active_tags.name' => 'blue')
      end
    end
  end
end
