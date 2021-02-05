# frozen_string_literal: true

class <%= model_class %> < Sequel::Model
  include Praxis::Mapper::SequelCompat
  
end