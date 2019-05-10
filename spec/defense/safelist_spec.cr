require "../spec_helper"

describe "Defense.safelist" do
  it "creates a safelist rule" do
    Defense.safelists.size.should eq(0)
    Defense.safelist { true }
    Defense.safelists.size.should eq(1)
  end

  it "if the request is blocked but the safelisted block matches, the request is not blocked" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.safelist { |req, rep| req.headers["user-agent"]? == "bot" }
    Defense.blocklist { true }

    ctx = HTTP::Server::Context.new(request, response)
    handler = Defense::Handler.new
    handler.next = ->(ctx : HTTP::Server::Context) {}

    handler.call(ctx)
    client_response = Helper.client_response(io, ctx)
    client_response.status.should eq(HTTP::Status::OK)
  end

  it "if the request is blocked and one of several safelisted blocks matches, the request is not blocked" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.safelist { |req, rep| req.headers["user-agent"]? == "not-a-bot" }
    Defense.safelist { |req, rep| req.headers["user-agent"]? == "bot" }
    Defense.blocklist { true }

    ctx = HTTP::Server::Context.new(request, response)
    handler = Defense::Handler.new
    handler.next = ->(ctx : HTTP::Server::Context) {}

    handler.call(ctx)
    client_response = Helper.client_response(io, ctx)
    client_response.status.should eq(HTTP::Status::OK)
  end

  it "if the request is blocked and the safelisted block doesn't match, the request is blocked" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.safelist { |req, rep| req.headers["user-agent"]? == "not-a-bot" }
    Defense.blocklist { true }

    ctx = HTTP::Server::Context.new(request, response)
    handler = Defense::Handler.new
    handler.next = ->(ctx : HTTP::Server::Context) {}

    handler.call(ctx)
    client_response = Helper.client_response(io, ctx)
    client_response.status.should eq(HTTP::Status::FORBIDDEN)
    client_response.body.should eq("Forbidden\n")
  end
end
