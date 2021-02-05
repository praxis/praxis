# frozen_string_literal: true

class CreateUsersTable < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |table|
      table.column :uuid, :string, null: false
      table.column :first_name, :string, null: false
      table.column :last_name, :string
      table.column :email, :string
    end
  end
end
