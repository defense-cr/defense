require "../spec_helper"

describe "Defense.blocklist" do
  it "does not block the request if the block doesn't match the request" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.blocklist { |req, res| req.headers["user-agent"]? == "not-a-bot" }

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::OK)
  end

  it "blocks the request if the block matches the request" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.blocklist { |req, res| req.headers["user-agent"]? == "bot" }

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::FORBIDDEN)
    response.body.should eq("Forbidden\n")
  end

  it "blocks the request if one of several blocks matches the request" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.blocklist { |req, res| req.headers["user-agent"]? == "not-a-bot" }
    Defense.blocklist { |req, res| req.headers["user-agent"]? == "bot" }

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::FORBIDDEN)
    response.body.should eq("Forbidden\n")
  end

  it "adapts the blocklisted response based on the value of Defense.blocklisted_response" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.blocklist { |req, res| req.headers["user-agent"]? == "bot" }
    Defense.blocklisted_response = ->(response : HTTP::Server::Response) do
      response.status = HTTP::Status::UNAUTHORIZED
      response.content_type = "application/json"
      response.puts("{'hello':'world'}")
    end

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::UNAUTHORIZED)
    response.body.should eq("{'hello':'world'}\n")
  end
end
