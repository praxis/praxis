guard 'rspec', cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec/" }
  watch('spec/functional_spec.rb')  { "spec/" }
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/functional_spec.rb" }
  watch(%r{^app/(.+)\.rb$})     { "spec/" }

end
