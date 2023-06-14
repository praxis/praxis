# frozen_string_literal: true

require 'active_record'

if ActiveRecord.gem_version < Gem::Version.new('6')
  require_relative 'active_record_patches/5x'
elsif ActiveRecord.gem_version < Gem::Version.new('6.1')
  require_relative 'active_record_patches/6_0'
else
  # As of 7.0.4 our 6.1-plus patches still work
  require_relative 'active_record_patches/6_1_plus'
end
