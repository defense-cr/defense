require "../spec_helper"

describe "Defense.fail2ban" do
  it "does not block a valid request" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/", HTTP::Headers{"REMOTE_ADDR"=> "1.2.3.4"})
    response = HTTP::Server::Response.new(io)

    Defense.blocklist do |req, res|
      Defense::Fail2Ban.filter("spec-#{req.remote_address}", maxretry: 2, bantime: 60, findtime: 60) do
        (req.query =~ /FAIL/) != nil
      end
    end

    client_response = Helper.call_handler(io, request, response)
    client_response.status.should eq(HTTP::Status::OK)
  end

  it "does block a request which match the query" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/?filter=FAIL", HTTP::Headers{"REMOTE_ADDR"=> "1.2.3.4"})
    response = HTTP::Server::Response.new(io)

    Defense.blocklist do |req, _|
      Defense::Fail2Ban.filter("spec-#{req.remote_address}", maxretry: 2, bantime: 60, findtime: 60) do
        (req.query =~ /FAIL/) != nil
      end
    end

    client_response = Helper.call_handler(io, request, response)
    client_response.status.should eq(HTTP::Status::FORBIDDEN)
  end
end
