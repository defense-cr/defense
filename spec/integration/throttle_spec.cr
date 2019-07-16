require "../spec_helper"

describe "Defense.throttle" do
  it "does not block the requests before exceeding the rule" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.throttle("my-throttle-rule", limit: 1, period: 60) { |req| req.headers["user-agent"]? }

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::OK)
  end

  it "blocks the requests that exceed the rule" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.throttle("my-throttle-rule", limit: 5, period: 60) { |req| req.headers["user-agent"]? }

    5.times { Helper.call_handler(request) }

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::TOO_MANY_REQUESTS)
    response.body.should eq("Retry later\n")
  end

  it "adapts the throttled response based on the value of Defense.throttled_response" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.throttle("my-throttle-rule", limit: 2, period: 60) { |req| req.headers["user-agent"]? }
    Defense.throttled_response = ->(response : HTTP::Server::Response) do
      response.status = HTTP::Status::UNAUTHORIZED
      response.content_type = "application/json"
      response.puts("{'hello':'world'}")
    end

    2.times { Helper.call_handler(request) }

    response = Helper.call_handler(request)
    response.status.should eq(HTTP::Status::UNAUTHORIZED)
    response.body.should eq("{'hello':'world'}\n")
  end

  it "blocks requests only within the defined period" do
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"user-agent" => "bot"})

    Defense.throttle("my-throttle-rule", limit: 3, period: 1) { |req| req.headers["user-agent"]? }

    Helper.call_handler(request).status.should eq(HTTP::Status::OK)
    Helper.call_handler(request).status.should eq(HTTP::Status::OK)
    Helper.call_handler(request).status.should eq(HTTP::Status::OK)
    Helper.call_handler(request).status.should eq(HTTP::Status::TOO_MANY_REQUESTS)

    sleep(0.1)

    Helper.call_handler(request).status.should eq(HTTP::Status::TOO_MANY_REQUESTS)

    sleep(0.1)

    Helper.call_handler(request).status.should eq(HTTP::Status::TOO_MANY_REQUESTS)

    sleep(1)

    Helper.call_handler(request).status.should eq(HTTP::Status::OK)
    Helper.call_handler(request).status.should eq(HTTP::Status::OK)
    Helper.call_handler(request).status.should eq(HTTP::Status::OK)
    Helper.call_handler(request).status.should eq(HTTP::Status::TOO_MANY_REQUESTS)
  end
end
