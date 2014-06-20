source 'https://rubygems.org'

#gem 'skeletor', path: '../../skeletor'
gem 'taylor', path: '../../taylor'
gem 'attributor', path: '../../attributor'

gem 'rack'
gem 'mustermann'
gem 'activesupport'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'rspec-given'
  gem 'bundler'

  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
end

group :test do

  gem 'rack-test', :require => 'rack/test'
  gem 'simplecov', :require => false

  gem 'fuubar', '2.0.0.rc1'
end
