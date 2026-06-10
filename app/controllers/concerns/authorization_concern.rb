# frozen_string_literal: true

module AuthorizationConcern
  extend ActiveSupport::Concern

  included do
    helper_method :current_ability
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  def require_admin!
    return if current_user&.role_admin?
    respond_to do |f|
      f.html { flash[:alert] = 'Admin access required.'; redirect_back(fallback_location: root_path) }
      f.json { render json: { error: 'Forbidden — admin only' }, status: :forbidden }
    end
  end

  def require_editor_or_above!
    return if current_user&.role_admin? || current_user&.role_editor?
    respond_to do |f|
      f.html { flash[:alert] = 'You do not have permission to perform this action.'; redirect_back(fallback_location: root_path) }
      f.json { render json: { error: 'Forbidden' }, status: :forbidden }
    end
  end
end
