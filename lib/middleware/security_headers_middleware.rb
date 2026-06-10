# frozen_string_literal: true

# Register in config/application.rb:
#   require_relative '../lib/middleware/security_headers_middleware'
#   config.middleware.insert_before 0, SecurityHeadersMiddleware
class SecurityHeadersMiddleware
  CSP = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob: https:",
    "font-src 'self' data:",
    "connect-src 'self' https:",
    "frame-ancestors 'none'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'"
  ].join('; ').freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    headers.merge!(security_headers) unless asset_path?(env['PATH_INFO'])
    [status, headers, response]
  end

  private

  def security_headers
    {
      'X-Frame-Options'           => 'DENY',
      'X-Content-Type-Options'    => 'nosniff',
      'X-XSS-Protection'          => '1; mode=block',
      'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains; preload',
      'Referrer-Policy'           => 'strict-origin-when-cross-origin',
      'Permissions-Policy'        => 'camera=(), microphone=(), geolocation=()',
      'Content-Security-Policy'   => CSP
    }
  end

  def asset_path?(path)
    path&.start_with?('/assets', '/packs', '/rails/active_storage')
  end
end
