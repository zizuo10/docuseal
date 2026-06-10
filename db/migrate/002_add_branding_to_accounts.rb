# frozen_string_literal: true

class AddBrandingToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :reminder_interval_days, :integer, default: 3, null: false
    add_column :accounts, :reminder_max_count,      :integer, default: 5, null: false
    add_column :accounts, :reminders_enabled,       :boolean, default: true, null: false
  end
end
