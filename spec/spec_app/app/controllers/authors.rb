# frozen_string_literal: true

require_relative 'base_class'

class Authors < BaseClass
  include Praxis::Controller

  implements ApiResources::Authors
  include Praxis::Extensions::Rendering

  def model_class
    ActiveAuthor
  end

  def base_query
    # Artificially set a base query that has joins, including a join against the base authors table (to test aliasing)
    # Note: in order to make sure we know what table name to refer to, we need to add our special reference (based on path)
    # This way, regardles of filters and/or ordering potentially being applied, we will always point to the correct alias
    books_ref = Praxis::Extensions::AttributeFiltering::ActiveRecordFilterQueryBuilder.build_reference_value('/books', query: model_class)
    inner_authors_ref = Praxis::Extensions::AttributeFiltering::ActiveRecordFilterQueryBuilder.build_reference_value('/books/author', query: model_class)
    model_class.distinct.joins(books: :author)
               .references(books_ref).where('"/books".simple_name LIKE ?', 'book%')
               .references(inner_authors_ref).where("#{inner_authors_ref}.id > ?", 0)
  end

  def index
    objs = build_query(base_query).all
    display(objs)
  end

  def show(id:, **_args)
    model = build_query(base_query.where(id: id)).first
    return Praxis::Mapper::ResourceNotFound.new(id: id, type: model_class) if model.nil?

    display(model)
  end
end
