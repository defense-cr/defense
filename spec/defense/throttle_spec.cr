require "spec"
require "../../src/defense"

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

  it "doesn't match a non-matching request" do
    request = HTTP::Request.new("GET", "/")
    response = HTTP::Server::Response.new(IO::Memory.new(""))

    Defense.throttle("my-throttle-rule", limit: 2, period: 100) { |req, res| req.headers["user-agent"]? }

    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
    Defense.throttles["my-throttle-rule"].matched_by?(request, response).should be_false
  end
end
