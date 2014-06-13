require 'strscan'

path = '/clouds/2/instances/751/volumes/15'

s = StringScanner.new(path)

until s.eos?
  #p s.scan %r|/|
  #p s.scan %r|\w+|
  p s.skip(%r|/|)
  #p s.scan_until(%r|\w+|)
  p s.scan %r|\w+|
end