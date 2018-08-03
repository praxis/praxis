require 'pp'
require 'json'

require 'bundler/setup'

require 'pry'

$:.unshift File.expand_path('lib', __dir__)

require 'praxis'

run Praxis::Application.new.setup