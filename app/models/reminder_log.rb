# frozen_string_literal: true

class ReminderLog < ApplicationRecord
  STATUSES = %w[sent failed].freeze

  belongs_to :submission

  validates :email,   presence: true
  validates :status,  inclusion: { in: STATUSES }
  validates :sent_at, presence: true

  scope :sent,   -> { where(status: 'sent') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(sent_at: :desc) }

  def self.count_for(submission)
    where(submission:, status: 'sent').count
  end
end
