# frozen_string_literal: true

class SignatureReminderJob < ApplicationJob
  queue_as :reminders
  sidekiq_options retry: 3, dead: false

  def perform
    pending_submitters.find_each do |submitter|
      process_submitter(submitter)
    rescue StandardError => e
      Rails.logger.error("[SignatureReminderJob] submitter #{submitter.id}: #{e.message}")
    end
  end

  private

  def pending_submitters
    Submitter
      .joins(submission: :account)
      .where(completed_at: nil)
      .where(accounts: { reminders_enabled: true })
      .where.not(email: [nil, ''])
      .includes(submission: :account)
  end

  def process_submitter(submitter)
    submission = submitter.submission
    account    = submission.account
    return if submission.completed_at.present?
    return if ReminderLog.count_for(submission) >= account.reminder_max_count
    return unless reminder_due?(submitter, account)

    send_reminder(submitter, submission, account, ReminderLog.count_for(submission) + 1)
  end

  def reminder_due?(submitter, account)
    interval       = account.reminder_interval_days.days
    last_sent_at   = ReminderLog.where(submission: submitter.submission,
                                       email: submitter.email, status: 'sent').maximum(:sent_at)
    reference_time = last_sent_at || submitter.submission.created_at
    Time.current >= reference_time + interval
  end

  def send_reminder(submitter, submission, account, attempt)
    SignatureReminderMailer.remind(submitter:, submission:, account:).deliver_now
    ReminderLog.create!(submission:, email: submitter.email, attempt:, status: 'sent', sent_at: Time.current)
    Rails.logger.info("[SignatureReminderJob] Reminder ##{attempt} sent to #{submitter.email} for submission #{submission.id}")
  rescue StandardError => e
    ReminderLog.create!(submission:, email: submitter.email, attempt:, status: 'failed', sent_at: Time.current)
    Rails.logger.error("[SignatureReminderJob] Failed #{submitter.email}: #{e.message}")
    raise
  end
end
