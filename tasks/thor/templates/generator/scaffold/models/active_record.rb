# frozen_string_literal: true

class <%= model_class %> < ActiveRecord::Base
  include Praxis::Mapper::ActiveModelCompat
  
end