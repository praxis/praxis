Gem::Specification.new do |s|
  s.name               = "praxis"
  s.version            = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Josep M. Blanquer"]
  s.date = %q{2014-06-19}
  s.description = %q{API Framework}
  s.email = %q{blanquer@rightscale.com}
  s.files = ["README.md", "lib/praxis.rb"] + Dir['tasks/*']
  s.homepage = %q{http://rubygems.org/gems/praxis}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{2.2.1}
  s.required_ruby_version = '~> 2.0'
  s.summary = %q{Building APIs the way you want it.}
  s.bindir = 'bin'
  s.executables << 'praxis'

  s.add_dependency 'rack'
  s.add_dependency 'mustermann'
  s.add_dependency 'activesupport'
  s.add_dependency 'ruport'
  s.add_dependency 'pry'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-bundler'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'pry-stack_explorer'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'fuubar', '2.0.0.rc1'
end
