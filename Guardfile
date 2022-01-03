# frozen_string_literal: true

guard :rspec, cmd: 'bundle exec rspec --format=Fuubar', \
              all_after_pass: false, all_on_start: false, failed_mode: :focus do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { 'spec/' }
  watch('spec/functional_spec.rb') { 'spec/' }
  watch(%r{^lib/(.+)\.rb$})     { |_m| 'spec/functional_spec.rb' }
  watch(%r{^app/(.+)\.rb$})     { 'spec/' }
  watch(%r{^spec/support}) { 'spec/' }
end
