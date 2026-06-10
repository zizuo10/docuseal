# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include AuthorizationConcern
  include AuditLoggingConcern

  include ActiveStorage::SetCurrent
  include Pagy::Backend

  impersonates :user

  before_action :authenticate_user!
  before_action :set_current_account

  check_authorization

  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied do |e|
    respond_to do |format|
      format.html do
        flash[:alert] = e.message.presence || 'You are not authorized to perform this action.'
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: 'Forbidden' }, status: :forbidden }
    end
  end

  helper_method :current_account

  def after_sign_in_path_for(resource)
    audit_log!('login_success', resource:)
    super
  end

  private

  def current_account
    @current_account ||= current_user&.account
  end

  def set_current_account
    Current.account = current_account if defined?(Current)
  end

  def default_url_options
    Docuseal.default_url_options
  end
end
