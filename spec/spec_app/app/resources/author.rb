require_relative 'base'

module Resources
  class Author < Resources::Base
    model ::ActiveAuthor
  end
end
