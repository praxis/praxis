lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'praxis/version'

Gem::Specification.new do |spec|
  spec.name          = "praxis"
  spec.version       = Praxis::VERSION
  spec.authors = ["Josep M. Blanquer","Dane Jensen"]
  spec.date = "2014-08-19"
  spec.summary = 'Building APIs the way you want it.'

  spec.email = ["blanquer@gmail.com","dane.jensen@gmail.com"]

  spec.homepage = "https://github.com/rightscale/praxis"
  spec.license = "MIT"
  spec.required_ruby_version = ">=2.1"

  spec.require_paths = ["lib"]
  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir = 'bin'
  spec.executables << 'praxis'

  spec.add_dependency 'rack', '~> 1'
  spec.add_dependency 'mustermann', '~> 0'
  spec.add_dependency 'activesupport', '>= 3'
  spec.add_dependency 'ruport', '~> 1'
  spec.add_dependency 'mime', '~> 0'
  spec.add_dependency 'praxis-mapper', '~> 3.1'
  spec.add_dependency 'praxis-blueprints', '~> 1.1'
  spec.add_dependency 'attributor', '~> 2.2'
  spec.add_dependency 'thor', '~> 0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 0.9'
  spec.add_development_dependency 'rake-notes', '~> 0'
  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'pry-byebug', '~> 1'
  spec.add_development_dependency 'pry-stack_explorer', '~> 0'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rspec-its', '~> 1'
  spec.add_development_dependency 'rspec-collection_matchers', '~> 1'
  spec.add_development_dependency 'guard', '~> 2'
  spec.add_development_dependency 'guard-rspec', '~> 4'
  spec.add_development_dependency 'guard-bundler', '~> 2'
  spec.add_development_dependency 'rack-test', '~> 0'
  spec.add_development_dependency 'simplecov', '~> 0'
  spec.add_development_dependency 'fuubar', '~> 2'
  spec.add_development_dependency 'yard', '~> 0'
end
