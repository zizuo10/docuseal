# frozen_string_literal: true

# Include in Account model: include AccountBranding
module AccountBranding
  extend ActiveSupport::Concern

  LOGO_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp image/svg+xml].freeze
  LOGO_MAX_SIZE      = 2.megabytes

  included do
    has_one_attached :logo

    validates :logo,
              content_type: { in: LOGO_CONTENT_TYPES, message: 'must be PNG, JPEG, GIF, WebP, or SVG' },
              size:         { less_than: LOGO_MAX_SIZE, message: 'must be smaller than 2 MB' },
              if: -> { logo.attached? }

    validates :reminder_interval_days,
              numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 },
              allow_nil: true
  end

  def logo_url
    return nil unless logo.attached?
    Rails.application.routes.url_helpers.url_for(logo)
  rescue StandardError
    nil
  end

  def remove_logo!
    logo.purge_later if logo.attached?
  end
end
