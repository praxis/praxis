require 'pry'

namespace :praxis do 
  task :console => :environment do
    pry
  end
end