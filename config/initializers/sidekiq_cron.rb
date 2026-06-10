# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      'signature_reminder_job' => {
        'cron'        => '0 * * * *',
        'class'       => 'SignatureReminderJob',
        'queue'       => 'reminders',
        'description' => 'Send reminder emails for pending document signatures'
      }
    )
  end
end
