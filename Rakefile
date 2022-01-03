# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'praxis'
require 'praxis/tasks'

require 'rspec/core/rake_task'

require 'bundler/gem_tasks'

RSpec::Core::RakeTask.new(:spec)

task default: :spec
