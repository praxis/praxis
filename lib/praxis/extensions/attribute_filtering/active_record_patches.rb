# frozen_string_literal: true

require 'active_record'

maj, min, = ActiveRecord.gem_version.segments

case maj
when 5
  require_relative 'active_record_patches/5x'
when 6
  if min.zero?
    require_relative 'active_record_patches/6_0'
  else
    require_relative 'active_record_patches/6_1_plus'
  end
when 7
  require_relative 'active_record_patches/6_1_plus'
else
  # raise 'Filtering only supported for ActiveRecord >= 5 && <= 6'
end
