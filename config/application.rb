# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

module Docuseal
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.time_zone = 'UTC'
    config.i18n.available_locales = %i[en fr de es it pt zh ar he ja ko nl pl sv uk]
    config.i18n.default_locale    = :en
    config.i18n.load_path        += Dir[Rails.root.join('config/locales/**/*.{rb,yml}')]
    config.active_job.queue_adapter = :sidekiq
    config.action_mailer.default_url_options = {
      host:     ENV.fetch('HOST', 'localhost'),
      port:     ENV.fetch('PORT', 3000),
      protocol: Rails.env.production? ? 'https' : 'http'
    }
    # ENTERPRISE: Security headers + rate limiting
    require_relative '../lib/middleware/security_headers_middleware'
    config.middleware.insert_before 0, SecurityHeadersMiddleware
    require 'rack/attack'
    config.middleware.use Rack::Attack
  end
end
