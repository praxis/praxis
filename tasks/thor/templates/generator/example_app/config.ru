# -p 8888

ENV['RACK_ENV'] ||= 'development'
Bundler.setup(:default, ENV['RACK_ENV'])
Bundler.require(:default, ENV['RACK_ENV'])

# Want to take advantage of some of the Praxis' extensions for:
# API field selection (a la GraphQL) - for querying and rendering
# API filtering extensions (to add "where clauses") in listings
# Views and partial rendering (for ActiveRecord models)
require 'praxis/plugins/mapper_plugin'
require 'praxis/mapper/active_model_compat'
# Want to take advantage of the pagination and sorting extensions as well
require 'praxis/plugins/pagination_plugin'

# Start the sqlite DB
case ENV['RACK_ENV']
when 'test'
  ActiveRecord::Base.establish_connection(
    adapter:  'sqlite3',
    database: ':memory:'
  )
else
  ActiveRecord::Base.establish_connection(
    adapter:  'sqlite3',
    database: "development.sqlite3"
  )
end

run Praxis::Application.instance.setup
