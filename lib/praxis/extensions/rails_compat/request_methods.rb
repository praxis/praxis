# frozen_string_literal: true

# Make Praxis' request derive from ActionDispatch
if defined? Praxis::Request
  puts "IT seems that we're trying to redefine Praxis' request parent too late."
  puts '-> try to include the Rails compat pieces earlier in the bootstrap process (before Praxis::Request is requried)'
  exit(-1)
end

begin
  require 'praxis/request_superclassing'

  module Praxis
    require 'action_dispatch'
    Praxis.request_superclass = ::ActionDispatch::Request
  end
  require 'praxis/request'
end
