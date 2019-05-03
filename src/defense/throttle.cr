module Defense
  class Throttle
    getter :name, :limit, :period, :block

    def initialize(@name : String, @limit : Int32, @period : Int32, &@block : (HTTP::Request, HTTP::Server::Response) -> String?)
    end

    def matched_by?(request : HTTP::Request, response : HTTP::Server::Response) : Bool
      discriminator = block.call(request, response)
      return false unless discriminator

      store = Defense.store
      count = store.increment(discriminator, period)

      count > limit
    end
  end
end
