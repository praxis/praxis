require 'active_record'

maj, min, _ = ActiveRecord.gem_version.segments

if maj == 5
  require_relative 'active_record_patches/5x.rb'
elsif maj == 6
  if min == 0
    require_relative 'active_record_patches/6_0.rb'
  else
    require_relative 'active_record_patches/6_1_plus.rb'
  end
else
  raise "Filtering only supported for ActiveRecord >= 5 && <= 6"  
end