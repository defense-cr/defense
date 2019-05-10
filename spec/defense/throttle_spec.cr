require "../spec_helper"

def period
  60
end

describe "Defense.throttle" do
  it "creates a throttle rule" do
    Defense.throttle("my-throttle-rule", limit: 2, period: period) { }
    Defense.throttles.size.should eq(1)
    Defense.throttles.has_key?("my-throttle-rule").should be_true
  end

  it "matches a request based on the rules" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(IO::Memory.new(""))

    Defense.throttle("user-agent", limit: 1, period: period) { |req, res| req.headers["user-agent"]? }

    Defense.throttles["user-agent"].matched_by?(request, response).should be_false
    Defense.throttles["user-agent"].matched_by?(request, response).should be_true
    Defense.store.has_key?("defense:throttle:user-agent:bot").should be_true
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
    client_response = Helper.client_response(io, ctx)
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
    client_response = Helper.client_response(io, ctx)
    client_response.status.should eq(HTTP::Status::TOO_MANY_REQUESTS)
    client_response.body.should eq("Retry later\n")
  end

  it "adapts the throttled response based on the value of Defense.throttled_response" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.throttle("my-throttle-rule", limit: 1, period: period) { |req, res| req.headers["user-agent"]? }
    Defense.throttled_response = ->(response : HTTP::Server::Response) do
      response.status = HTTP::Status::UNAUTHORIZED
      response.content_type = "application/json"
      response.puts("{'hello':'world'}")
    end

    ctx = HTTP::Server::Context.new(request, response)
    handler = Defense::Handler.new
    handler.next = ->(ctx : HTTP::Server::Context) {}

    2.times { handler.call(ctx) }
    client_response = Helper.client_response(io, ctx)
    client_response.status.should eq(HTTP::Status::UNAUTHORIZED)
    client_response.body.should eq("{'hello':'world'}\n")
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
