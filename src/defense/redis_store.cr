require "redis"

module Defense
  class RedisStore < Store
    def initialize(url : String? = nil)
      if !url.nil?
        @redis = Redis::Client.new(URI.parse(url))
      elsif ENV.has_key?("REDIS_URL")
        @redis = Redis::Client.from_env("REDIS_URL")
      else
        @redis = Redis::Client.new
      end
    end

    def increment(unprefixed_key : String, expires_in : Int32) : Int64
      key = prefix_key(unprefixed_key)

      @redis.multi do |r|
        r.incr(key)
        r.expire(key, expires_in)
      end.first.as(Int64)
    end

    def exists?(unprefixed_key : String) : Bool
      @redis.exists(prefix_key(unprefixed_key)) == 1
    end

    def read(unprefixed_key : String) : Int64 | Nil
      @redis.get(prefix_key(unprefixed_key)).try(&.to_i64)
    end

    def reset
      keys = @redis.keys("#{prefix}:*")
      return if keys.empty?
      @redis.del(keys.map(&.to_s))
    end
  end
end
