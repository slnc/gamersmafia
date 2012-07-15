require "redis"

# Stores key/value pairs. Functions to this module are not guaranteed to
# succeed.
module Keystore
  PREFIXES = [
    :http_global_errors_internal_404,
    :http_global_errors_external_404,
  ]

  def self.init
    return if defined?($redis)
    $redis = Redis.new(:db => App.redis_db)
  end

  def self.cleanup_keys
    init
    yesterday = 1.day.ago.strftime("%Y%m%d")
    self.expire("http.global.errors.internal_404.#{yesterday}", 86400 * 365)
    self.expire("http.global.errors.external_404.#{yesterday}", 86400 * 365)
  end

  def self.method_missing(method_id, *args)
    init
    begin
      $redis.send(method_id, *args)
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error("redis.#{method_id} failed: Redis DB is down: #{e}")
      nil
    end
  end
end
