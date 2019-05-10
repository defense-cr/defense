require "spec"
require "../../src/defense"

if ENV["STORE"]? == "memory"
  Defense.store = Defense::MemoryStore.new
end

Spec.before_each do
  Defense.store.reset
  Defense.throttles.clear
  Defense.blocklists.clear
end

module Helper
  def self.client_response(io : IO, ctx : HTTP::Server::Context) : HTTP::Client::Response
    ctx.response.close
    io.rewind
    HTTP::Client::Response.from_io(io, decompress: false)
  end
end
