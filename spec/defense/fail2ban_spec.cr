require "../spec_helper"

describe "Defense.fail2ban" do
  describe "while the discriminator is not banned" do
    context "receives a valid request" do
      it "responds with success" do
        io = IO::Memory.new
        request = HTTP::Request.new("GET", "/", HTTP::Headers{"Host"=> "1.2.3.4"})
        response = HTTP::Server::Response.new(io)

        Defense.blocklist do |req, res|
          Defense::Fail2Ban.filter("spec-#{req.host_with_port}", maxretry: 2, bantime: 60, findtime: 60) do
            (req.query =~ /FAIL/) != nil
          end
        end

        client_response = Helper.call_handler(io, request, response)
        client_response.status.should eq(HTTP::Status::OK)
      end
    end

    context "receives an invalid request" do
      it "responds with forbidden" do
        io = IO::Memory.new
        request = HTTP::Request.new("GET", "/?filter=FAIL", HTTP::Headers{"Host"=> "1.2.3.4"})
        response = HTTP::Server::Response.new(io)

        Defense.blocklist do |req, _|
          Defense::Fail2Ban.filter("spec-#{req.host_with_port}", maxretry: 2, bantime: 60, findtime: 60) do
            (req.query =~ /FAIL/) != nil
          end
        end

        client_response = Helper.call_handler(io, request, response)
        client_response.status.should eq(HTTP::Status::FORBIDDEN)
      end

      it "increments the fail counter" do
        io = IO::Memory.new
        request = HTTP::Request.new("GET", "/?filter=FAIL", HTTP::Headers{"Host"=> "1.2.3.4"})
        response = HTTP::Server::Response.new(io)

        Defense.blocklist do |req, _|
          Defense::Fail2Ban.filter("spec-#{req.host_with_port}", maxretry: 2, bantime: 60, findtime: 60) do
            (req.query =~ /FAIL/) != nil
          end
        end

        Helper.call_handler(io, request, response)

        ip = request.host_with_port
        Defense.store.read("defense:fail2ban:count:spec-#{ip}").should eq("1")
      end
    end
  end

  describe "when the discriminator has been banned already" do
  end
end
