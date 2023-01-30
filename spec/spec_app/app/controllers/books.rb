# frozen_string_literal: true

class Books < BaseClass
  include Praxis::Controller

  implements ApiResources::Books
  include Praxis::Extensions::Rendering

  def model_class
    ActiveBook
  end
  def base_query
    # Make sure we add the distinct clause, that's what we always want for index requests
    # as we can have multiple copies of the same top level model if there were joins due
    # to manual conditions added, or simply conditions added when filters are used on related tables
    model_class.distinct
  end

  def index
    objs = build_query(base_query).all
    display(objs)
  end

  def show(id:, **_args)
    model = build_query(base_query.where(id: id)).first
    return Praxis::Mapper::ResourceNotFound.new(id: id, type: self.model_class) if model.nil?

    display(model)
  end
end
