# frozen_string_literal: true

class CreateReminderLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :reminder_logs do |t|
      t.references :submission, null: false, foreign_key: true
      t.string     :email,      null: false
      t.integer    :attempt,    null: false, default: 1
      t.string     :status,     null: false, default: 'sent'
      t.datetime   :sent_at,    null: false
      t.timestamps
    end
    add_index :reminder_logs, [:submission_id, :sent_at]
  end
end
