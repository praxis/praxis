source 'https://rubygems.org'

gem 'taylor', git: 'git@github.com:rightscale/taylor.git', branch: 'master'
gem 'attributor', git: 'git@github.com:rightscale/attributor.git', branch: 'master'
#gem 'taylor', path: '../taylor'
#gem 'attributor', path: '../attributor'

gem 'thor'
gem 'rack'
gem 'mustermann'
gem 'activesupport'

gem 'ruport'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-collection_matchers'

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
