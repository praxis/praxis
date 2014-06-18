source 'https://rubygems.org'

# Underlying frameworks
gem 'rack-mount'

#gem 'skeletor', path: '../../skeletor'
gem 'taylor', path: '../../taylor'
gem 'attributor', path: '../../attributor'

gem 'activesupport'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development, :test do
  gem 'rake'
  gem 'rspec'

  gem 'bundler'

  gem 'guard'
  gem 'guard-rspec'

  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
end

group :test do
  gem 'rack-test', :require => 'rack/test'
  gem 'simplecov', :require => false

  gem 'fuubar'
end
