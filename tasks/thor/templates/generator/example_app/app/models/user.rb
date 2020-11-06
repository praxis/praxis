
class User < ActiveRecord::Base
  # So it can be used in all the automatic query/filtering extensions
  include Praxis::Mapper::ActiveModelCompat

end
