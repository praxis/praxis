require 'active_record'

class DatabaseHelper
  # Simple DB seeding to avoid bringing in other gems like FactoryGirl etc.
  # This does the job for an example seeder
  def self.seed!
    user_data = [
      {id: 11, first_name: 'Peter', last_name: 'Praxis', uuid: 'deadbeef', email: 'peter@pan.com'},
      {id: 12, first_name: 'Alice', last_name: 'Trellis', uuid: 'beefdead', email: 'alice@wonderland.com'}
    ]
    (100..199).each do |i|
      user_data.push id: i, first_name: "User-#{i}", last_name: "Last-#{i}", uuid: SecureRandom.hex(16).to_s
    end
    user_data.each_with_index do |data, i|
      ::User.create(**data)
    end
    puts "Database seeded."
  end
end