# frozen_string_literal: true

module Api
  class BrandingController < ApiBaseController
    before_action :require_admin!

    def show
      render json: branding_payload
    end

    def update
      if current_account.update(account_branding_params)
        audit_log!('branding_updated', resource: current_account)
        render json: branding_payload
      else
        render json: { errors: current_account.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy_logo
      if current_account.logo.attached?
        current_account.remove_logo!
        audit_log!('logo_removed', resource: current_account)
        render json: { message: 'Logo removed.' }
      else
        render json: { error: 'No logo attached.' }, status: :not_found
      end
    end

    private

    def account_branding_params
      params.require(:account).permit(:logo, :reminder_interval_days, :reminder_max_count, :reminders_enabled)
    end

    def branding_payload
      {
        logo_url:               current_account.logo_url,
        logo_attached:          current_account.logo.attached?,
        reminder_interval_days: current_account.reminder_interval_days,
        reminder_max_count:     current_account.reminder_max_count,
        reminders_enabled:      current_account.reminders_enabled
      }
    end
  end
end
