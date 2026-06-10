# frozen_string_literal: true

Devise.setup do |config|
  config.stretches         = Rails.env.test? ? 1 : 12
  config.password_length   = 12..128
  config.lock_strategy     = :failed_attempts
  config.maximum_attempts  = 10
  config.unlock_strategy   = :time
  config.unlock_in         = 30.minutes
  config.timeout_in        = 8.hours
  config.remember_for      = 2.weeks
  config.paranoid          = true
end

Warden::Manager.before_failure do |env, _opts|
  params = env['action_dispatch.request.parameters'] || {}
  email  = params.dig('user', 'email').to_s.downcase.presence
  AuditLog.record!(
    account:    Account.find_by(id: params['account_id']) || Account.first,
    action:     'login_failure',
    ip_address: env['REMOTE_ADDR'],
    user_agent: env['HTTP_USER_AGENT'],
    metadata:   { email: email&.gsub(/.(?=.*@)/, '*') }
  )
rescue StandardError => e
  Rails.logger.warn("[AuditLog] login_failure not recorded: #{e.message}")
end
