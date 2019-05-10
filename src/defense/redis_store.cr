require "redis"

module Defense
  class RedisStore < Store
    def initialize(url : String?)
      @redis = Redis::PooledClient.new(url: url)
    end

    def increment(unprefixed_key : String, expires_in : Int32) : Int64
      count = Redis::Future.new

      key = "#{prefix}:#{unprefixed_key}"

      @redis.pipelined do |pipeline|
        count = pipeline.incr(key).as(Redis::Future)
        pipeline.expire(key, expires_in)
      end

      count.value.as(Int64)
    end

    def reset
      keys = @redis.keys("#{prefix}:*")
      return if keys.empty?
      @redis.del(keys)
    end
  end
end
