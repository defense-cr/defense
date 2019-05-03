require "redis"

module Defense
  class RedisStore < Store
    def initialize(url : String?)
      @redis = Redis::PooledClient.new(url: url)
    end

    def increment(key : String, expires_in : Int32) : Int64
      count = Redis::Future.new

      @redis.pipelined do |pipeline|
        count = pipeline.incr(key).as(Redis::Future)
        pipeline.expire(key, expires_in)
      end

      count.value.as(Int64)
    end

    def reset
      # TODO: When we introduce namespaces, clean only namespaced data
      @redis.flushdb
    end
  end
end
