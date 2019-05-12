require "../spec_helper"

describe "Defense.safelist" do
  it "if the request is blocked but the safelisted block matches, the request is not blocked" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.safelist { |req, rep| req.headers["user-agent"]? == "bot" }
    Defense.blocklist { true }

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::OK)
  end

  it "if the request is blocked and one of several safelisted blocks matches, the request is not blocked" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.safelist { |req, rep| req.headers["user-agent"]? == "not-a-bot" }
    Defense.safelist { |req, rep| req.headers["user-agent"]? == "bot" }
    Defense.blocklist { true }

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::OK)
  end

  it "if the request is blocked and the safelisted block doesn't match, the request is blocked" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.safelist { |req, rep| req.headers["user-agent"]? == "not-a-bot" }
    Defense.blocklist { true }

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::FORBIDDEN)
    response.body.should eq("Forbidden\n")
  end
end
