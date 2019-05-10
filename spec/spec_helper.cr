require "spec"
require "../../src/defense"

if ENV["STORE"]? == "memory"
  Defense.store = Defense::MemoryStore.new
end

original_throttled_response = Defense.throttled_response
original_blocklisted_response = Defense.blocklisted_response

Spec.before_each do
  Defense.store.reset
  Defense.throttles.clear
  Defense.blocklists.clear
  Defense.safelists.clear
  Defense.throttled_response = original_throttled_response
  Defense.blocklisted_response = original_blocklisted_response
end

module Helper
  def self.client_response(io : IO, ctx : HTTP::Server::Context) : HTTP::Client::Response
    ctx.response.close
    io.rewind
    HTTP::Client::Response.from_io(io, decompress: false)
  end
end
