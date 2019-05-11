module Defense
  private class Blocklist
    getter :block

    def initialize(&@block : (HTTP::Request, HTTP::Server::Response) -> Bool)
    end

    def matched_by?(request : HTTP::Request, response : HTTP::Server::Response) : Bool
      block.call(request, response)
    end
  end
end
