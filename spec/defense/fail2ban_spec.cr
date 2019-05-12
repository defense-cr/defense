require "../spec_helper"

describe "Defense.fail2ban" do
  describe "while the discriminator is not banned" do
    context "receives a valid request" do
      it "responds with success" do
        request = HTTP::Request.new("GET", "/", HTTP::Headers{"Host" => "1.2.3.4"})

        Defense.blocklist do |req, res|
          Defense::Fail2Ban.filter("spec-#{req.host_with_port}", maxretry: 2, bantime: 60, findtime: 60) do
            (req.query =~ /FAIL/) != nil
          end
        end

        response = Helper.call_handler(request)
        response.status.should eq(HTTP::Status::OK)
      end
    end

    context "receives an invalid request" do
      it "responds with forbidden" do
        request = HTTP::Request.new("GET", "/?filter=FAIL", HTTP::Headers{"Host" => "1.2.3.4"})

        Defense.blocklist do |req, _|
          Defense::Fail2Ban.filter("spec-#{req.host_with_port}", maxretry: 2, bantime: 60, findtime: 60) do
            (req.query =~ /FAIL/) != nil
          end
        end

        response = Helper.call_handler(request)
        response.status.should eq(HTTP::Status::FORBIDDEN)
      end

      it "increments the fail counter" do
        request = HTTP::Request.new("GET", "/?filter=FAIL", HTTP::Headers{"Host" => "1.2.3.4"})

        Defense.blocklist do |req, _|
          Defense::Fail2Ban.filter("spec-#{req.host_with_port}", maxretry: 2, bantime: 60, findtime: 60) do
            (req.query =~ /FAIL/) != nil
          end
        end

        Helper.call_handler(request)

        ip = request.host_with_port
        Defense.store.read("defense:fail2ban:count:spec-#{ip}").should eq("1")
      end
    end
  end

  describe "when the discriminator has been banned already" do
  end
end
