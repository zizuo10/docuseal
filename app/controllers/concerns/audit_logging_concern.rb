# frozen_string_literal: true

module AuditLoggingConcern
  extend ActiveSupport::Concern

  included do
    after_action :auto_log_significant_action
  end

  def audit_log!(action, resource: nil, metadata: {})
    AuditLog.record!(
      account:    current_account,
      user:       current_user,
      action:     action.to_s,
      resource:,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      metadata:
    )
  end

  private

  SIGNIFICANT_ACTIONS = {
    'sessions#create'                 => 'login_success',
    'sessions#destroy'                => 'logout',
    'templates#create'                => 'document_created',
    'templates#update'                => 'document_updated',
    'templates#destroy'               => 'document_deleted',
    'submissions#create'              => 'document_sent',
    'submissions#destroy'             => 'document_deleted',
    'users#create'                    => 'user_created',
    'users#update'                    => 'user_updated',
    'users#destroy'                   => 'user_deleted',
    'api/branding#update'             => 'branding_updated',
    'api/branding#destroy_logo'       => 'logo_removed',
    'personalization_settings#create' => 'branding_updated'
  }.freeze

  def auto_log_significant_action
    audit_name = SIGNIFICANT_ACTIONS["#{controller_path}##{action_name}"]
    return unless audit_name
    return unless response.successful? || response.redirect?
    resource = instance_variable_get(:"@#{controller_name.singularize}")
    AuditLog.record!(
      account: current_account, user: current_user, action: audit_name,
      resource:, ip_address: request.remote_ip, user_agent: request.user_agent
    )
  rescue StandardError => e
    Rails.logger.warn("[AuditLoggingConcern] #{e.message}")
  end
end
