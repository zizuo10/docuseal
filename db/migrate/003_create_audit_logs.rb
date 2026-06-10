# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :account,       null: false, foreign_key: true
      t.references :user,          null: true,  foreign_key: true
      t.string     :action,        null: false
      t.string     :resource_type
      t.bigint     :resource_id
      t.string     :ip_address
      t.string     :user_agent
      t.jsonb      :metadata,      default: {}
      t.datetime   :created_at,    null: false
    end
    add_index :audit_logs, [:account_id, :action]
    add_index :audit_logs, [:account_id, :created_at]
    add_index :audit_logs, [:resource_type, :resource_id]
  end
end
