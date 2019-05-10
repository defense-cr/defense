require "http/request"
require "http/server/response"
require "./defense/throttle"
require "./defense/blocklist"
require "./defense/store"
require "./defense/memory_store"
require "./defense/redis_store"
require "./defense/handler"

module Defense
  @@blocklisted_response : (HTTP::Server::Response) -> Nil = ->(response : HTTP::Server::Response) do
    response.status = HTTP::Status::FORBIDDEN
    response.content_type = "text/plain"
    response.puts("Forbidden\n")
  end

  def self.blocklisted_response
    @@blocklisted_response
  end

  def self.blocklisted_response=(block : (HTTP::Server::Response) -> Nil)
    @@blocklisted_response = block
  end

  @@throttled_response : (HTTP::Server::Response) -> Nil = ->(response : HTTP::Server::Response) do
    response.status = HTTP::Status::TOO_MANY_REQUESTS
    response.content_type = "text/plain"
    response.puts("Retry later\n")
  end

  def self.throttled_response
    @@throttled_response
  end

  def self.throttled_response=(block : (HTTP::Server::Response) -> Nil)
    @@throttled_response = block
  end

  def self.throttle(name : String, limit : Int32, period : Int32, &block : (HTTP::Request, HTTP::Server::Response) -> String?)
    throttles[name] = Throttle.new(name, limit, period, &block)
  end

  def self.blocklist(&block : (HTTP::Request, HTTP::Server::Response) -> Bool)
    blocklists << Blocklist.new(&block)
  end

  def self.throttles
    @@throttles ||= Hash(String, Throttle).new
  end

  def self.blocklists
    @@blocklists ||= Array(Blocklist).new
  end

  def self.store : Store
    @@store ||= RedisStore.new(url: ENV["REDIS_URL"]?)
  end

  def self.store=(store : Store)
    @@store = store
  end

  def self.throttled?(request, response)
    throttles.any? do |_, throttle|
      throttle.matched_by?(request, response)
    end
  end

  def self.blocklisted?(request, response)
    blocklists.any? do |blocklist|
      blocklist.matched_by?(request, response)
    end
  end
end
