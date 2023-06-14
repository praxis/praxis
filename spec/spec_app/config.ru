# frozen_string_literal: true

require 'json'

require 'bundler/setup'

require 'pry'

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'praxis'

application = Praxis::Application.instance

application.setup

run application
