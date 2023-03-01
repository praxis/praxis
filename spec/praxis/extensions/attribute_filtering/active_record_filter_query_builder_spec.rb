# frozen_string_literal: true

require 'spec_helper'

require 'praxis/extensions/attribute_filtering'
require 'praxis/extensions/attribute_filtering/active_record_filter_query_builder'

describe Praxis::Extensions::AttributeFiltering::ActiveRecordFilterQueryBuilder do
  let(:root_resource) { ActiveBookResource }
  let(:filters_map) { root_resource.instance_variable_get(:@_filters_map) }
  let(:base_model) { root_resource.model }
  let(:base_query) { base_model }
  let(:instance) { described_class.new(query: base_query, model: base_model, filters_map: filters_map) }

  shared_examples 'subject_equivalent_to' do |expected_result|
    it do
      loaded_ids = subject.all.map(&:id).sort
      expected_result = expected_result.call if expected_result.is_a?(Proc)
      expected_ids = expected_result.all.map(&:id).sort
      expect(loaded_ids).to_not be_empty
      expect(loaded_ids).to eq(expected_ids)
    end
  end

  # Poorman's way to compare SQL queries...
  shared_examples 'subject_matches_sql' do |expected_sql|
    it do
      gen_sql = subject.all.to_sql
      # Strip blank at the beggining (and end) of every line
      # ...and recompose it by adding an extra space at the beginning of each one instead
      exp = expected_sql.split(/\n/).map do |line|
        " #{line.strip}"
      end.join.strip
      expect(gen_sql).to eq(exp)
    end
  end

  context 'initialize' do
    it 'sets the right things to the instance' do
      instance
      expect(instance.instance_variable_get(:@initial_query)).to eq(base_query)
      expect(instance.model).to eq(base_model)
      expect(instance.filters_map).to eq(filters_map)
    end
  end
  context 'generate' do
    subject { instance.generate(filters) }
    let(:filters) { Praxis::Types::FilteringParams.load(filters_string) }

    context 'with no filters' do
      let(:filters_string) { '' }
      it 'does not modify the query' do
        expect(subject).to be(base_query)
      end
    end
    context 'with flat AND conditions' do
      context 'by a simple field' do
        context 'that maps to the same name' do
          let(:filters_string) { 'category_uuid=deadbeef1' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1')
        end
        context 'same-name filter mapping works' do
          context 'even if ther was not a filter explicitly defined for it' do
            let(:filters_string) { 'category_uuid=deadbeef1' }
            it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1')
          end

          context 'but if it is a field that does not exist in the model' do
            let(:filters_string) { 'nonexisting=valuehere' }
            it 'it blows up with the right error' do
              expect { subject }.to raise_error(/Filtering by nonexisting is not allowed/)
            end
          end
        end
        context 'that maps to a different name' do
          let(:filters_string) { 'name=Book1' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.where(simple_name: 'Book1')
        end
        context 'that is mapped as a nested struct' do
          let(:filters_string) { 'fake_nested.name=Book1' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.where(simple_name: 'Book1')
        end
        context 'passing multiple values' do
          context 'without fuzzy matching' do
            let(:filters_string) { 'category_uuid=deadbeef1,deadbeef2' }
            it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: %w[deadbeef1 deadbeef2])
          end
          context 'with fuzzy matching' do
            let(:filters_string) { 'category_uuid=*deadbeef1,deadbeef2*' }
            it 'is not supported' do
              expect do
                subject
              end.to raise_error(
                Praxis::Extensions::AttributeFiltering::MultiMatchWithFuzzyNotAllowedByAdapter,
                /Please use multiple OR clauses instead/
              )
            end
          end
        end
      end

      context 'by a field or a related model' do
        context 'for a belongs_to association' do
          let(:filters_string) { 'author.name=author2' }
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

        context 'by just an association filter condition' do
          context 'for a belongs_to association with NO ROWS' do
            let(:filters_string) { 'category!!' }
            it_behaves_like 'subject_equivalent_to', ActiveBook.where.missing(:category)
          end

          context 'for a direct has_many association asking for missing rows' do
            let(:filters_string) { 'primary_tags!!' }
            it_behaves_like 'subject_equivalent_to',
                            ActiveBook.where.missing(:primary_tags)
          end
          context 'for a direct has_many association asking for non-missing rows' do
            let(:filters_string) { 'primary_tags!' }
            it_behaves_like 'subject_equivalent_to',
                            ActiveBook.left_outer_joins(:primary_tags).where.not('primary_tags.id' => nil)
          end

          context 'for a has_many through association with NO ROWS' do
            let(:filters_string) { 'tags!!' }
            it_behaves_like 'subject_equivalent_to', ActiveBook.where.missing(:tags)
          end

          context 'for a has_many through association with SOME ROWS' do
            let(:filters_string) { 'tags!' }
            it_behaves_like 'subject_equivalent_to', ActiveBook.left_outer_joins(:tags).where.not('tags.id' => nil)
          end

          context 'for a 3 levels deep has_many association with NO ROWS' do
            let(:filters_string) { 'category.books.taggings!!' }
            it_behaves_like 'subject_equivalent_to',
                            ActiveBook.left_outer_joins(category: { books: :taggings }).where('category.books.taggings.id' => nil)
          end

          context 'for a 3 levels deep has_many association WITH SIME ROWS' do
            let(:filters_string) { 'category.books.taggings!' }
            it_behaves_like 'subject_equivalent_to',
                            ActiveBook.left_outer_joins(category: { books: :taggings }).where.not('category.books.taggings.id' => nil)
          end
        end
      end

      # NOTE: apparently AR when conditions are build with strings in the where clauses (instead of names, etc)
      # it decides to parenthesize them, even when there's only 1 condition. Hence the silly parentization of
      # these SQL fragments here (and others)
      context 'by using all supported operators' do
        # rubocop:disable Lint/ConstantDefinitionInBlock
        PREF = Praxis::Extensions::AttributeFiltering::ALIAS_TABLE_PREFIX
        COMMON_SQL_PREFIX = <<~SQL
          SELECT "active_books".* FROM "active_books"
          LEFT OUTER JOIN
            "active_authors" "#{PREF}/author" ON "#{PREF}/author"."id" = "active_books"."author_id"
        SQL
        # rubocop:enable Lint/ConstantDefinitionInBlock
        context '=' do
          let(:filters_string) { 'author.id=11' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id = 11')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."id" = 11)
          SQL
        end
        context '= (with array)' do
          let(:filters_string) { 'author.id=11,22' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id IN (11,22)')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."id" IN (11,22))
          SQL
        end
        context '!=' do
          let(:filters_string) { 'author.id!=11' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id <> 11')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."id" <> 11)
          SQL
        end
        context '!= (with array)' do
          let(:filters_string) { 'author.id!=11,888' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id NOT IN (11,888)')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."id" NOT IN (11,888))
          SQL
        end
        context '>' do
          let(:filters_string) { 'author.id>1' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id > 1')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."id" > 1)
          SQL
        end
        context '<' do
          let(:filters_string) { 'author.id<22' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id < 22')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."id" < 22)
          SQL
        end
        context '>=' do
          let(:filters_string) { 'author.id>=22' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id >= 22')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."id" >= 22)
          SQL
        end
        context '<=' do
          let(:filters_string) { 'author.id<=22' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id <= 22')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."id" <= 22)
          SQL
        end
        context '!' do
          let(:filters_string) { 'author.id!' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.id IS NOT NULL')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."id" IS NOT NULL)
          SQL
        end
        context '!!' do
          let(:filters_string) { 'author.name!!' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name IS NULL')
          it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
            WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."name" IS NULL)
          SQL
        end
        context 'including LIKE fuzzy queries' do
          context 'LIKE' do
            let(:filters_string) { 'author.name=author*' }
            it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name LIKE "author%"')
            it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
              WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."name" LIKE 'author%')
            SQL
          end
          context 'NOT LIKE' do
            let(:filters_string) { 'author.name!=foobar*' }
            it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name NOT LIKE "foobar%"')
            it_behaves_like 'subject_matches_sql', COMMON_SQL_PREFIX + <<~SQL
              WHERE ("#{PREF}/author"."id" IS NOT NULL) AND ("#{PREF}/author"."name" NOT LIKE 'foobar%')
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
              LEFT OUTER JOIN "active_categories" ON "active_categories"."uuid" = "active_books"."category_uuid"
              LEFT OUTER JOIN "active_books" "books_active_categories" ON "books_active_categories"."category_uuid" = "active_categories"."uuid"
              LEFT OUTER JOIN "active_taggings" "#{PREF}/category/books/taggings" ON "/category/books/taggings"."book_id" = "books_active_categories"."id"
              WHERE ("#{PREF}/category/books/taggings"."id" IS NOT NULL) AND ("#{PREF}/category/books/taggings"."tag_id" = 1)
              AND ("#{PREF}/category/books/taggings"."label" = 'primary')
          SQL
        end
        context 'that contain multiple joins to the same table' do
          let(:filters_string) { 'taggings.tag.taggings.tag_id=1' }
          it_behaves_like 'subject_equivalent_to',
                          ActiveBook.joins(taggings: { tag: :taggings }).where('taggings_active_tags.tag_id=1')
        end
      end

      context 'by multiple fields' do
        context 'adds the where clauses for the top model if fields belong to it' do
          let(:filters_string) { 'category_uuid=deadbeef1&name=Book1' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1', simple_name: 'Book1')
        end
        context 'adds multiple where clauses for same nested relationship join (instead of multiple joins with 1 clause each)' do
          let(:filters_string) { 'taggings.label=primary&taggings.tag_id=2' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:taggings).where('active_taggings.label' => 'primary', 'active_taggings.tag_id' => 2)
        end
      end

      context 'uses fully qualified names for conditions (disambiguate fields)' do
        context 'when we have a join table condition that has the same field' do
          let(:filters_string) { 'name=Book1&category.books.name=Book3' }
          it_behaves_like 'subject_equivalent_to', ActiveBook.joins(category: :books)
                                                             .where('simple_name': 'Book1')
                                                             .where('books_active_categories.simple_name': 'Book3')
          it_behaves_like 'subject_matches_sql', <<~SQL
            SELECT "active_books".* FROM "active_books"
              LEFT OUTER JOIN "active_categories" ON "active_categories"."uuid" = "active_books"."category_uuid"
              LEFT OUTER JOIN "active_books" "#{PREF}/category/books" ON "#{PREF}/category/books"."category_uuid" = "active_categories"."uuid"#{'    '}
            WHERE ("active_books"."simple_name" = 'Book1')
            AND ("#{PREF}/category/books"."id" IS NOT NULL) AND ("#{PREF}/category/books"."simple_name" = 'Book3')
          SQL
        end

        context 'it qualifies them even if there are no joined tables/conditions at all' do
          let(:filters_string) { 'id=11' }
          it_behaves_like 'subject_matches_sql', <<~SQL
            SELECT "active_books".* FROM "active_books"
              WHERE ("active_books"."id" = 11)
          SQL
        end
      end
    end

    context 'with simple OR conditions' do
      context 'adds the where clauses for the top model if fields belong to it' do
        let(:filters_string) { 'category_uuid=deadbeef1|name=Book1' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1').or(ActiveBook.where(simple_name: 'Book1'))
      end
      context 'supports top level parenthesis' do
        let(:filters_string) { '(category_uuid=deadbeef1|name=Book1)' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1').or(ActiveBook.where(simple_name: 'Book1'))
      end
      context 'adds multiple where clauses for same nested relationship join (instead of multiple joins with 1 clause each)' do
        let(:filters_string) { 'taggings.label=primary|taggings.tag_id=2' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:taggings).where('active_taggings.label' => 'primary')
                                                           .or(ActiveBook.joins(:taggings).where('active_taggings.tag_id' => 2))
      end
    end

    context 'with combined AND and OR conditions' do
      let(:filters_string) { '(category_uuid=deadbeef1|category_uuid=deadbeef2)&(name=Book1|name=Book2)' }
      it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1').or(ActiveBook.where(category_uuid: 'deadbeef2'))
                                                         .and(ActiveBook.where(simple_name: 'Book1').or(ActiveBook.where(simple_name: 'Book2')))
      it_behaves_like 'subject_matches_sql', <<~SQL
        SELECT "active_books".* FROM "active_books"
          WHERE ("active_books"."category_uuid" = 'deadbeef1' OR "active_books"."category_uuid" = 'deadbeef2')
          AND ("active_books"."simple_name" = 'Book1' OR "active_books"."simple_name" = 'Book2')
      SQL

      context 'adds multiple where clauses for same nested relationship join (instead of multiple joins with 1 clause each)' do
        let(:filters_string) { 'taggings.label=primary|taggings.tag_id=2' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:taggings).where('active_taggings.label' => 'primary')
                                                           .or(ActiveBook.joins(:taggings).where('active_taggings.tag_id' => 2))
        it_behaves_like 'subject_matches_sql', <<~SQL
          SELECT "active_books".* FROM "active_books"
            LEFT OUTER JOIN "active_taggings" "/taggings" ON "/taggings"."book_id" = "active_books"."id"
            WHERE ("/taggings"."id" IS NOT NULL) AND ("/taggings"."label" = 'primary' OR "/taggings"."tag_id" = 2)
        SQL
      end

      context 'adds multiple where clauses for same nested relationship join even if it is a ! or !! filter without a value (instead of multiple joins with 1 clause each)' do
        let(:filters_string) { 'taggings!&(taggings.label=primary|taggings.tag_id=2)' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:taggings).where('active_taggings.label' => 'primary')
                                                           .or(ActiveBook.joins(:taggings).where('active_taggings.tag_id' => 2))
        it_behaves_like 'subject_matches_sql', <<~SQL
          SELECT "active_books".* FROM "active_books"
            LEFT OUTER JOIN "active_taggings" "/taggings" ON "/taggings"."book_id" = "active_books"."id"
            WHERE ("/taggings"."id" IS NOT NULL) AND ("/taggings"."label" = 'primary' OR "/taggings"."tag_id" = 2)
        SQL
      end

      context 'works well with ORs at a parent table along with joined associations with no rows' do
        let(:filters_string) { 'name=Book1005|category!!' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.where.missing(:category)
                                                           .or(ActiveBook.where.missing(:category).where(simple_name: 'Book1005'))
        it_behaves_like 'subject_matches_sql', <<~SQL
          SELECT "active_books".* FROM "active_books"
            LEFT OUTER JOIN "active_categories" "/category" ON "/category"."uuid" = "active_books"."category_uuid"
            WHERE ("active_books"."simple_name" = 'Book1005' OR "/category"."uuid" IS NULL)
        SQL
      end

      context '3-deep AND and OR conditions' do
        let(:filters_string) { '(category.name=cat2|(taggings.label=primary&tags.name=red))&category_uuid=deadbeef1' }
        it_behaves_like('subject_equivalent_to', proc do
          base = ActiveBook.left_outer_joins(:category, :taggings, :tags)

          and1_or1 = base.where('category.name': 'cat2').where.not('category.uuid': nil)

          and1_or2_and1 = base.where('taggings.label': 'primary').where.not('taggings.id': nil)
          and1_or2_and2 = base.where('tags.name': 'red').where.not('tags.id': nil)
          and1_or2 = and1_or2_and1.and(and1_or2_and2)

          and1 = and1_or1.or(and1_or2)
          and2 = base.where(category_uuid: 'deadbeef1')

          and1.and(and2)
        end)

        it_behaves_like 'subject_matches_sql', <<~SQL
          SELECT "active_books".* FROM "active_books"#{' '}
            LEFT OUTER JOIN "active_categories" "/category" ON "/category"."uuid" = "active_books"."category_uuid"#{' '}
            LEFT OUTER JOIN "active_taggings" "/taggings" ON "/taggings"."book_id" = "active_books"."id"#{' '}
            LEFT OUTER JOIN "active_tags" "/tags" ON "/tags"."id" = "/taggings"."tag_id"#{'         '}
            WHERE (("/category"."uuid" IS NOT NULL)
                  AND ("/category"."name" = 'cat2')
                    OR ("/taggings"."id" IS NOT NULL)
                        AND ("/taggings"."label" = 'primary')
                        AND ("/tags"."id" IS NOT NULL)
                        AND ("/tags"."name" = 'red'))
                  AND ("active_books"."category_uuid" = 'deadbeef1')#{' '}
        SQL
      end
    end

    context 'ActiveRecord continues to work as expected (with our patches)' do
      context 'using a deep join with repeated tables' do
        subject { ActiveBook.joins(taggings: { tag: :taggings }).where('taggings_active_tags.tag_id=1') }
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
        subject! { ActiveBook.joins(tags: { books: { taggings: :book } }).where('books_active_taggings.simple_name="Book2"') }
        it 'performs query' do
          expect(subject.to_a).to_not be_empty
        end
        it_behaves_like 'subject_matches_sql', <<~SQL
          SELECT "active_books".* FROM "active_books"#{' '}
               INNER JOIN "active_taggings" ON "active_taggings"."book_id" = "active_books"."id"
               INNER JOIN "active_tags" ON "active_tags"."id" = "active_taggings"."tag_id"
               INNER JOIN "active_taggings" "taggings_active_tags_join" ON "taggings_active_tags_join"."tag_id" = "active_tags"."id"#{' '}
               INNER JOIN "active_books" "books_active_tags" ON "books_active_tags"."id" = "taggings_active_tags_join"."book_id"#{' '}
               INNER JOIN "active_taggings" "taggings_active_books" ON "taggings_active_books"."book_id" = "books_active_tags"."id"#{' '}
               INNER JOIN "active_books" "books_active_taggings" ON "books_active_taggings"."id" = "taggings_active_books"."book_id"
               WHERE (books_active_taggings.simple_name="Book2")#{'             '}
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
        #     LEFT OUTER JOIN "active_taggings" ON "active_taggings"."label" = 'primary'
        #                 AND "active_taggings"."book_id" = "active_books"."id"
        #     LEFT OUTER JOIN "active_tags" "/primary_tags" ON "/primary_tags"."id" = "active_taggings"."tag_id"
        #     WHERE ("/primary_tags"."name" = 'blue')
        # SQL
      end
    end
  end

  context '.valid_path?' do
    it 'suceeds for reachable model columns' do
      expect(described_class.valid_path?(ActiveBook, ['added_column'])).to be_truthy
      expect(described_class.valid_path?(ActiveBook, %w[author books added_column])).to be_truthy
      expect(described_class.valid_path?(ActiveBook, %w[author books simple_name])).to be_truthy
    end
    it 'suceeds for reachable leaf associations' do
      expect(described_class.valid_path?(ActiveBook, ['author'])).to be_truthy
      expect(described_class.valid_path?(ActiveBook, %w[author books])).to be_truthy
    end
    it 'returns false for invalid model columns' do
      expect(described_class.valid_path?(ActiveBook, ['not_a_column'])).to be_falsy
      expect(described_class.valid_path?(ActiveBook, %w[author books not_here])).to be_falsy
      expect(described_class.valid_path?(ActiveBook, %w[author books name])).to be_falsy
    end
  end

  context '_mapped_filter' do
    let(:root_resource) { ActiveBookResource }
    let(:filters_map) { root_resource.instance_variable_get(:@_filters_map) }

    context 'for explicitly mapped values' do
      %i[id name name_is_not author.name category.books.taggings.label]
        .each do |name|
        it "suceeds for #{name}" do
          mapped_value = filters_map[name]
          expect(mapped_value).to_not be_nil
          expect(instance.send(:_mapped_filter, name)).to eq(mapped_value)
        end
      end
    end

    context 'for not mapped values' do
      context 'that are valid model columns/associations paths' do
        %i[added_column author.books.added_column author.books].each do |name|
          it "returns (and caches) the same valid path for #{name}" do
            expect(filters_map[name]).to be_nil
            expect(instance.send(:_mapped_filter, name)).to eq(name)

            expect(filters_map[name]).to eq(name)
          end
        end
      end
      context 'that are not model columns/associations paths' do
        %i[not_a_column author.books.not_here].each do |name|
          it "returns nil (and does not cache) for #{name}" do
            expect(filters_map[name]).to be_nil
            expect(instance.send(:_mapped_filter, name)).to eq(nil)

            expect(filters_map[name]).to eq(nil)
          end
        end
      end
    end
  end
end
