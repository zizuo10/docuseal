# frozen_string_literal: true

class SignatureReminderMailer < ApplicationMailer
  def remind(submitter:, submission:, account:)
    @submitter  = submitter
    @submission = submission
    @account    = account
    @signing_url = build_signing_url(@submitter)
    prefix = @account.name.present? ? "[#{@account.name}] " : ''
    mail(to: @submitter.email,
         subject: "#{prefix}Reminder: Your signature is required",
         from: smtp_from)
  end

  private

  def smtp_from
    ENV.fetch('SMTP_FROM', "no-reply@#{ENV.fetch('SMTP_DOMAIN', 'docuseal.local')}")
  end

  def build_signing_url(submitter)
    sign_submission_url(
      slug: submitter.slug,
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
  rescue StandardError
    '#'
  end
end
