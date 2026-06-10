# frozen_string_literal: true

Rack::Attack.enabled = true

Rack::Attack.cache.store = if ENV['REDIS_URL'].present?
  ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL'])
else
  ActiveSupport::Cache::MemoryStore.new
end

Rack::Attack.safelist('allow localhost') { |req| Rails.env.development? && req.ip == '127.0.0.1' }

# Login — 5 attempts per 20 seconds per IP
Rack::Attack.throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == '/sign_in' && req.post?
end

# Login — 10 attempts per 5 minutes per email
Rack::Attack.throttle('logins/email', limit: 10, period: 5.minutes) do |req|
  if req.path == '/sign_in' && req.post?
    req.params.dig('user', 'email').to_s.downcase.strip
  end
end

# API — 100 requests per minute per IP
Rack::Attack.throttle('api/ip', limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/api/')
end

# Password reset — 3 per hour per IP
Rack::Attack.throttle('password_reset/ip', limit: 3, period: 1.hour) do |req|
  req.ip if req.path.include?('password') && req.post?
end

# General — 1000 requests per hour per IP
Rack::Attack.throttle('req/ip', limit: 1000, period: 1.hour) do |req|
  req.ip unless req.path.start_with?('/assets', '/packs')
end

Rack::Attack.throttled_responder = lambda do |req|
  retry_after = (req.env['rack.attack.match_data'] || {})[:period]
  [429, { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s },
   [{ error: 'Too many requests. Please try again later.', retry_after: }.to_json]]
end

ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _req_id, payload|
  req = payload[:request]
  if %i[throttle blocklist].include?(req.env['rack.attack.match_type'])
    Rails.logger.warn("[Rack::Attack] #{req.env['rack.attack.match_type']} | IP=#{req.ip} PATH=#{req.path}")
  end
end
