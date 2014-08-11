namespace :praxis do
  task :console => :environment do
    begin
      require 'pry'
      pry
    rescue LoadError
      require 'irb'
      IRB.start
    end
  end
end
