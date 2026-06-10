# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true

  validates :action, presence: true

  before_update  { raise ActiveRecord::ReadOnlyRecord, 'AuditLog records are immutable' }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, 'AuditLog records cannot be deleted' }

  scope :recent,           -> { order(created_at: :desc) }
  scope :for_action,       ->(a) { where(action: a) }
  scope :login_attempts,   -> { where(action: %w[login_success login_failure]) }
  scope :document_actions, -> { where(action: %w[document_created document_signed document_sent]) }

  def self.record!(account:, action:, user: nil, resource: nil,
                   ip_address: nil, user_agent: nil, metadata: {})
    create!(
      account:, user:, action:,
      resource_type: resource&.class&.name,
      resource_id:   resource&.id,
      ip_address:    ip_address&.to_s&.truncate(45),
      user_agent:    user_agent&.to_s&.truncate(512),
      metadata:      metadata.to_h
    )
  rescue StandardError => e
    Rails.logger.error("[AuditLog] Failed to record #{action}: #{e.message}")
    nil
  end
end
