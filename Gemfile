source 'https://rubygems.org'

#gem 'skeletor', path: '../../skeletor'
gem 'taylor', git: 'git@github.com:rightscale/taylor.git', branch: 'master'
gem 'attributor', git: 'git@github.com:rightscale/attributor.git', branch: 'master'

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
