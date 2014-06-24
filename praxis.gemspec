Gem::Specification.new do |s|
  s.name               = "praxis"
  s.version            = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Josep M. Blanquer"]
  s.date = %q{2014-06-19}
  s.description = %q{API Framework}
  s.email = %q{blanquer@rightscale.com}
  s.files = ["README.md", "lib/praxis.rb"]
  s.homepage = %q{http://rubygems.org/gems/praxis}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{2.2.1}
  s.required_ruby_version = '~> 2.0'
  s.summary = %q{Building APIs the way you want it.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

