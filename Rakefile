$:.unshift File.expand_path('lib',__dir__)

require 'praxis'
require 'praxis/tasks'


require 'rake/notes/rake_task'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec