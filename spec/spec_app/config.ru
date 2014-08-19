require 'pp'
require 'json'

require 'bundler/setup'

require 'pry'

$:.unshift File.expand_path('lib', __dir__)

require 'praxis'


application = Praxis::Application.instance

application.setup

run application