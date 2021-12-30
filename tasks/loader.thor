require 'thor'

files = Dir[File.join(File.dirname(__FILE__), 'thor/*.rb')]
files.each do |f|
  require File.expand_path(f)
end
