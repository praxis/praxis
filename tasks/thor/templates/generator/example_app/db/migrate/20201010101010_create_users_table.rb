# frozen_string_literal: true

class CreateUsersTable < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |table|
      table.column :uuid, :integer
      table.column :first_name, :string
      table.column :last_name, :string
    end
  end
end
