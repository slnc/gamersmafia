require "redis"

# Stores key/value pairs. Functions to this module are not guaranteed to
# succeed.
module Keystore
  def self.init
    return if defined?($redis)
    $redis = Redis.new
  end

  def self.set(key, value)
    init
    begin
      $redis.set(key, value)
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error("redis.set failed: Redis DB is down: #{e}")
      nil
    end
  end

  def self.incr(key)
    init
    begin
      $redis.incr(key)
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error("redis.incr failed: Redis DB is down: #{e}")
      nil
    end
  end
end
