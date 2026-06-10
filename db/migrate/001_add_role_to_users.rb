# frozen_string_literal: true

class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer, default: 1, null: false
    add_index  :users, [:account_id, :role]
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET role = 0 WHERE id IN (SELECT MIN(id) FROM users GROUP BY account_id)"
      end
    end
  end
end
