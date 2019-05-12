module Defense
  private class Blocklist
    getter :name, :block

    def initialize(@name : String, &@block : (HTTP::Request, HTTP::Server::Response) -> Bool)
    end

    def matched_by?(request : HTTP::Request, response : HTTP::Server::Response) : Bool
      block.call(request, response)
    end
  end
end
