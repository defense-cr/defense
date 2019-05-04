require "spec"
require "../../src/defense"

if ENV["STORE"]? == "memory"
  Defense.store = Defense::MemoryStore.new
end

Spec.before_each do
  Defense.store.reset
end

def period
  60
end

def client_response(io : IO, ctx : HTTP::Server::Context) : HTTP::Client::Response
  ctx.response.close
  io.rewind
  HTTP::Client::Response.from_io(io, decompress: false)
end

describe "Defense.throttle" do
  it "stores the value in a class variable" do
    rule_name = "my-throttle-rule"
    Defense.throttle(rule_name, limit: 2, period: period) { }
    Defense.throttles.size.should eq(1)
    Defense.throttles.has_key?(rule_name).should be_true
  end

  it "matches a matching request" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(IO::Memory.new(""))

    Defense.throttle("my-throttle-rule", limit: 1, period: period) { |req, res| req.headers["user-agent"]? }

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_true
  end

  it "does not block the requests before exceeding the rule" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.throttle("my-throttle-rule", limit: 1, period: period) { |req, res| req.headers["user-agent"]? }

    ctx = HTTP::Server::Context.new(request, response)
    handler = Defense::Handler.new
    handler.next = ->(ctx : HTTP::Server::Context) {}

    handler.call(ctx)
    client_response = client_response(io, ctx)
    client_response.status.should eq(HTTP::Status::OK)
  end

  it "blocks the requests that exceed the rule" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.throttle("my-throttle-rule", limit: 1, period: period) { |req, res| req.headers["user-agent"]? }

    ctx = HTTP::Server::Context.new(request, response)
    handler = Defense::Handler.new
    handler.next = ->(ctx : HTTP::Server::Context) {}

    2.times { handler.call(ctx) }
    client_response = client_response(io, ctx)
    client_response.body.should eq("Retry later\n")
    client_response.status.should eq(HTTP::Status::TOO_MANY_REQUESTS)
  end

  it "doesn't match a non-matching request" do
    request = HTTP::Request.new("GET", "/")
    response = HTTP::Server::Response.new(IO::Memory.new(""))

    Defense.throttle("my-throttle-rule", limit: 2, period: period) { |req, res| req.headers["user-agent"]? }

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
  end

  it "matches within the defined period" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(IO::Memory.new(""))

    Defense.throttle("my-throttle-rule", limit: 2, period: period) { |req, res| req.headers["user-agent"]? }

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_true
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_true
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_true
  end

  it "doesn't match outside the defined period" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(IO::Memory.new(""))

    Defense.throttle("my-throttle-rule", limit: 2, period: 1) { |req, res| req.headers["user-agent"]? }

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_true

    sleep(0.1)

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_true

    sleep(1)

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
  end
end
