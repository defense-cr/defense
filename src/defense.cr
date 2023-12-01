require "http/request"
require "http/server/response"
require "uuid"
require "./defense/throttle"
require "./defense/blocklist"
require "./defense/fail2ban"
require "./defense/allow2ban"
require "./defense/safelist"
require "./defense/store"
require "./defense/memory_store"
require "./defense/redis_store"
require "./defense/handler"

module Defense
  def self.throttle(name : String, limit : Int32, period : Int32, &block : (HTTP::Request) -> String?)
    throttles[name] = Throttle.new(name, limit, period, &block)
  end

  def self.blocklist(name : String = UUID.random.to_s, &block : (HTTP::Request) -> Bool)
    blocklists[name] = Blocklist.new(name, &block)
  end

  def self.safelist(name : String = UUID.random.to_s, &block : (HTTP::Request) -> Bool)
    safelists[name] = Safelist.new(name, &block)
  end

  def self.throttled_response=(block : (HTTP::Server::Response) -> Nil)
    @@throttled_response = block
  end

  def self.blocklisted_response=(block : (HTTP::Server::Response) -> Nil)
    @@blocklisted_response = block
  end

  def self.reset
    store.reset
  end

  def self.store : Store
    @@store ||= RedisStore.new
  end

  def self.store=(store : Store)
    @@store = store
  end

  @@throttled_response : (HTTP::Server::Response) -> Nil = ->(response : HTTP::Server::Response) do
    response.status = HTTP::Status::TOO_MANY_REQUESTS
    response.content_type = "text/plain"
    response.puts("Retry later\n")
  end

  protected def self.throttled_response
    @@throttled_response
  end

  @@blocklisted_response : (HTTP::Server::Response) -> Nil = ->(response : HTTP::Server::Response) do
    response.status = HTTP::Status::FORBIDDEN
    response.content_type = "text/plain"
    response.puts("Forbidden\n")
  end

  protected def self.blocklisted_response
    @@blocklisted_response
  end

  protected def self.throttles
    @@throttles ||= Hash(String, Throttle).new
  end

  protected def self.blocklists
    @@blocklists ||= Hash(String, Blocklist).new
  end

  protected def self.safelists
    @@safelists ||= Hash(String, Safelist).new
  end

  protected def self.throttled?(request)
    throttles.any? do |_, throttle|
      throttle.matched_by?(request)
    end
  end

  protected def self.blocklisted?(request)
    blocklists.any? do |_, blocklist|
      blocklist.matched_by?(request)
    end
  end

  protected def self.safelisted?(request)
    safelists.any? do |_, safelist|
      safelist.matched_by?(request)
    end
  end
end
