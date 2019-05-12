require "../spec_helper"

private def headers
  HTTP::Headers{"Host" => "1.2.3.4"}
end

describe "Defense.fail2ban" do
  Spec.before_each do
    Defense.blocklist do |req, _|
      Defense::Fail2Ban.filter("spec-#{req.host_with_port}", maxretry: 2, bantime: 60, findtime: 60) do
        (req.query =~ /FAIL/) != nil
      end
    end
  end

  describe "while the discriminator is not banned" do
    context "receives a valid request" do
      it "responds with success" do
        request = HTTP::Request.new("GET", "/", headers)

        response = Helper.call_handler(request)
        response.status.should eq(HTTP::Status::OK)
      end
    end

    context "receives an invalid request" do
      context "while maxretry is not reached" do
        it "responds with forbidden" do
          request = HTTP::Request.new("GET", "/?filter=FAIL", headers)

          response = Helper.call_handler(request)
          response.status.should eq(HTTP::Status::FORBIDDEN)
        end

        it "increments the fail counter" do
          request = HTTP::Request.new("GET", "/?filter=FAIL", headers)

          Helper.call_handler(request)

          ip = request.host_with_port
          Defense.store.read("defense:fail2ban:count:spec-#{ip}").should eq("1")
        end

        it "is not banned yet" do
          request = HTTP::Request.new("GET", "/?filter=FAIL", headers)

          Helper.call_handler(request)

          ip = request.host_with_port
          Defense.store.read("defense:fail2ban:ban:spec-#{ip}").should be_nil
        end
      end

      context "when maxretry is reached" do
        it "responds with forbidden" do
          request = HTTP::Request.new("GET", "/?filter=FAIL", headers)

          Helper.call_handler(request)
          last_response = Helper.call_handler(request)

          last_response.status.should eq(HTTP::Status::FORBIDDEN)
        end

        it "increments the fail counter" do
          request = HTTP::Request.new("GET", "/?filter=FAIL", headers)

          2.times { Helper.call_handler(request) }

          ip = request.host_with_port
          Defense.store.read("defense:fail2ban:count:spec-#{ip}").should eq("2")
        end

        it "is banned" do
          request = HTTP::Request.new("GET", "/?filter=FAIL", headers)

          2.times { Helper.call_handler(request) }

          ip = request.host_with_port
          Defense.store.read("defense:fail2ban:ban:spec-#{ip}").should eq("1")
        end
      end
    end
  end

  describe "when the discriminator has been banned already" do
    Spec.before_each do
      2.times do
        Helper.call_handler(HTTP::Request.new("GET", "/?filter=FAIL", headers))
      end
    end

    context "receives a valid request for another discriminator" do
      it "responds with success" do
        headers = HTTP::Headers{"Host" => "4.3.2.1"}
        request = HTTP::Request.new("GET", "/", headers)

        response = Helper.call_handler(request)
        response.status.should eq(HTTP::Status::OK)
      end
    end

    context "receives a valid request for the banned discriminator" do
      it "responds with forbidden" do
        request = HTTP::Request.new("GET", "/", headers)

        response = Helper.call_handler(request)
        response.status.should eq(HTTP::Status::FORBIDDEN)
      end
    end

    context "receives an invalid request for the banned discriminator" do
      it "responds with forbidden" do
        request = HTTP::Request.new("GET", "/?filter=FAIL", headers)

        response = Helper.call_handler(request)
        response.status.should eq(HTTP::Status::FORBIDDEN)
      end
    end
  end
end
