require "spec"
require "../../src/defense"

if ENV["STORE"]? == "memory"
  Defense.store = Defense::MemoryStore.new
end

Spec.before_each do
  Defense.store.reset
end

describe "Defense.throttle" do
  it "stores the value in a class variable" do
    rule_name = "my-throttle-rule"
    Defense.throttle(rule_name, limit: 2, period: 100) { }
    Defense.throttles.size.should eq(1)
    Defense.throttles.has_key?(rule_name).should be_true
  end

  it "matches a matching request" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(IO::Memory.new(""))

    Defense.throttle("my-throttle-rule", limit: 1, period: 100) { |req, res| req.headers["user-agent"]? }

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_true
  end

  it "matches a matching request" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(IO::Memory.new)

    Defense.throttle("my-throttle-rule", limit: 1, period: 100) { |req, res| req.headers["user-agent"]? }

    ctx = HTTP::Server::Context.new(request, response)
    handler = Defense::Handler.new
    handler.next = ->(ctx : HTTP::Server::Context) {}

    handler.call(ctx)
    ctx.response.status.should eq(HTTP::Status::OK)

    handler.call(ctx)
    ctx.response.status.should eq(HTTP::Status::TOO_MANY_REQUESTS)
    # TODO: response.output.should eq("Retry later\n")

    # Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    # Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_true
  end

  it "doesn't match a non-matching request" do
    request = HTTP::Request.new("GET", "/")
    response = HTTP::Server::Response.new(IO::Memory.new(""))

    Defense.throttle("my-throttle-rule", limit: 2, period: 100) { |req, res| req.headers["user-agent"]? }

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
  end

  it "matches within the defined period" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(IO::Memory.new(""))

    Defense.throttle("my-throttle-rule", limit: 2, period: 100) { |req, res| req.headers["user-agent"]? }

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

    sleep(0.5)

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_true

    sleep(1)

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
  end
end
