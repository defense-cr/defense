require "spec"
require "../src/defense"

if ENV["STORE"]? == "memory"
  Defense.store = Defense::MemoryStore.new
end

# Reopen the class so we can have access to protected/private methods inside a test run.
module Defense
  ORIGINAL_THROTTLED_RESPONSE  = throttled_response
  ORGINAL_BLOCKLISTED_RESPONSE = blocklisted_response

  def self.reset_for_tests
    reset
    throttles.clear
    blocklists.clear
    safelists.clear
    Defense.throttled_response = ORIGINAL_THROTTLED_RESPONSE
    Defense.blocklisted_response = ORGINAL_BLOCKLISTED_RESPONSE
  end
end

Spec.before_each do
  Defense.reset_for_tests
end

module Helper
  def self.call_handler(request : HTTP::Request, response_io : IO = IO::Memory.new) : HTTP::Client::Response
    response = HTTP::Server::Response.new(response_io)
    ctx = HTTP::Server::Context.new(request, response)

    handler = Defense::Handler.new
    handler.next = ->(ctx : HTTP::Server::Context) {}
    handler.call(ctx)

    ctx.response.close
    response_io.rewind

    HTTP::Client::Response.from_io(response_io, decompress: false)
  end
end
