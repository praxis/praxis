namespace :praxis do
  task :environment do
    Praxis::Application.instance.setup
  end
end
