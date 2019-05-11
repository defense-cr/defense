require "spec"
require "../src/defense"

if ENV["STORE"]? == "memory"
  Defense.store = Defense::MemoryStore.new
end

original_throttled_response = Defense.throttled_response
original_blocklisted_response = Defense.blocklisted_response

Spec.before_each do
  Defense.reset
  Defense.throttled_response = original_throttled_response
  Defense.blocklisted_response = original_blocklisted_response
end

module Helper
  def self.client_response(io : IO, ctx : HTTP::Server::Context) : HTTP::Client::Response
    ctx.response.close
    io.rewind
    HTTP::Client::Response.from_io(io, decompress: false)
  end

  def self.call_handler(io : IO, request : HTTP::Request, response : HTTP::Server::Response) : HTTP::Client::Response
    ctx = HTTP::Server::Context.new(request, response)
    handler = Defense::Handler.new
    handler.next = ->(ctx : HTTP::Server::Context) {}

    handler.call(ctx)
    client_response(io, ctx)
  end
end
