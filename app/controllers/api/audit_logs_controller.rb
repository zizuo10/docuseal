# frozen_string_literal: true

module Api
  class AuditLogsController < ApiBaseController
    before_action :require_admin!

    def index
      logs = current_account.audit_logs.recent
      logs = logs.where(action: params[:action_filter])   if params[:action_filter].present?
      logs = logs.where(resource_type: params[:resource]) if params[:resource].present?
      logs = logs.where('created_at >= ?', params[:from]) if params[:from].present?
      logs = logs.where('created_at <= ?', params[:to])   if params[:to].present?
      pagy, logs = pagy(logs, limit: [params.fetch(:limit, 25).to_i, 100].min)
      render json: { data: logs.map { |l| serialize_log(l) }, pagination: pagy_metadata(pagy) }
    end

    def show
      log = current_account.audit_logs.find(params[:id])
      render json: serialize_log(log)
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Not found' }, status: :not_found
    end

    private

    def serialize_log(log)
      { id: log.id, action: log.action, resource_type: log.resource_type,
        resource_id: log.resource_id, user_id: log.user_id, user_email: log.user&.email,
        ip_address: log.ip_address, metadata: log.metadata, created_at: log.created_at.iso8601 }
    end
  end
end
