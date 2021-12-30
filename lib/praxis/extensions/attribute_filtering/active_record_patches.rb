require 'active_record'

maj, min, = ActiveRecord.gem_version.segments

if maj == 5
  require_relative 'active_record_patches/5x'
elsif maj == 6
  if min == 0
    require_relative 'active_record_patches/6_0'
  else
    require_relative 'active_record_patches/6_1_plus'
  end
else
  raise 'Filtering only supported for ActiveRecord >= 5 && <= 6'
end
