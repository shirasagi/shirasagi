module Cms::PublicFilter::PartCache
  extend ActiveSupport::Concern

  def fetch_part_cache(part)
    if part.ajax_view_cache_enabled?
      body = read_part_cache(part)
      return [ { "X-SS-Received-By" => "cms/public#part_cache" }, body ] if body
    end

    header, body = yield

    if part.ajax_view_cache_enabled?
      write_part_cache(part, body)
    end

    [ header, body ]
  end

  def read_part_cache(part)
    key = part.ajax_view_cache_key

    return false if !Rails.cache.exist?(key)
    body = Rails.cache.read(key)
    Rails.logger.info { "Successfully read part cache: #{key} (pid: #{Process.pid})" }
    body
  rescue => e
    Rails.logger.error { "Failed to read part cache: #{e.message}" }
    false
  end

  def write_part_cache(part, body)
    key = part.ajax_view_cache_key
    expire_seconds = part.ajax_view_expire_seconds.to_i

    if Rails.cache.write(key, body.to_s, expires_in: expire_seconds.seconds)
      Rails.logger.info { "Successfully write part cache: #{key} (expires_in #{expire_seconds}) (pid: #{Process.pid})" }
      true
    else
      Rails.logger.error { "Failed to write part cache: Rails.cache.write returns false" }
      false
    end
  rescue => e
    Rails.logger.error { "Failed to write part cache: #{e.message}" }
    false
  end
end
