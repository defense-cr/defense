require "../spec_helper"

describe "Defense.blocklist" do
  it "creates a blocklist rule" do
    Defense.blocklists.size.should eq(0)
    Defense.blocklist { true }
    Defense.blocklists.size.should eq(1)
  end

  it "does not block the request if the block doesn't match the request" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.blocklist { |req, res| req.headers["user-agent"]? == "not-a-bot" }

    client_response = Helper.call_handler(io, request, response)
    client_response.status.should eq(HTTP::Status::OK)
  end

  it "blocks the request if the block matches the request" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.blocklist { |req, res| req.headers["user-agent"]? == "bot" }

    client_response = Helper.call_handler(io, request, response)
    client_response.status.should eq(HTTP::Status::FORBIDDEN)
    client_response.body.should eq("Forbidden\n")
  end

  it "blocks the request if one of several blocks matches the request" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.blocklist { |req, res| req.headers["user-agent"]? == "not-a-bot" }
    Defense.blocklist { |req, res| req.headers["user-agent"]? == "bot" }

    client_response = Helper.call_handler(io, request, response)
    client_response.status.should eq(HTTP::Status::FORBIDDEN)
    client_response.body.should eq("Forbidden\n")
  end

  it "adapts the blocklisted response based on the value of Defense.blocklisted_response" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})
    response = HTTP::Server::Response.new(io)

    Defense.blocklist { |req, res| req.headers["user-agent"]? == "bot" }
    Defense.blocklisted_response = ->(response : HTTP::Server::Response) do
      response.status = HTTP::Status::UNAUTHORIZED
      response.content_type = "application/json"
      response.puts("{'hello':'world'}")
    end

    client_response = Helper.call_handler(io, request, response)
    client_response.status.should eq(HTTP::Status::UNAUTHORIZED)
    client_response.body.should eq("{'hello':'world'}\n")
  end
end
