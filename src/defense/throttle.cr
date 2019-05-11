module Defense
  private class Throttle
    getter :name, :limit, :period, :block

    def initialize(@name : String, @limit : Int32, @period : Int32, &@block : (HTTP::Request, HTTP::Server::Response) -> String?)
    end

    def matched_by?(request : HTTP::Request, response : HTTP::Server::Response) : Bool
      discriminator = block.call(request, response)
      return false unless discriminator

      count = store.increment("#{prefix}:#{discriminator}", period)

      count > limit
    end

    private def store
      Defense.store
    end

    private def prefix
      "throttle:#{name}"
    end
  end
end
