# frozen_string_literal: true
SimpleCov.profiles.define 'praxis' do
  add_filter '/config/'
  add_filter '/spec/'

  add_group 'lib', 'lib'
  add_group 'app', 'app'
end
