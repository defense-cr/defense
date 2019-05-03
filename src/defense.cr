require "http/request"
require "http/server/response"
require "./defense/throttle"
require "./defense/store"
require "./defense/memory_store"
require "./defense/redis_store"

module Defense
  def self.throttle(name : String, limit : Int32, period : Int32, &block : (HTTP::Request, HTTP::Server::Response) -> String?)
    throttles[name] = Throttle.new(name, limit, period, &block)
  end

  def self.throttles
    @@throttles ||= Hash(String, Throttle).new
  end

  def self.store : Store
    @@store ||= MemoryStore.new
  end

  def self.store=(store : Store)
    @@store = store
  end
end
