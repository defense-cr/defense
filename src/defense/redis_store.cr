require "redis"

module Defense
  class RedisStore < Store
    def initialize(url : String?)
      @redis = Redis::PooledClient.new(url: url)
    end

    def increment(unprefixed_key : String, expires_in : Int32) : Int64
      count = Redis::Future.new

      key = prefix_key(unprefixed_key)

      @redis.pipelined do |pipeline|
        count = pipeline.incr(key).as(Redis::Future)
        pipeline.expire(key, expires_in)
      end

      count.value.as(Int64)
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
