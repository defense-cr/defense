module Defense
  private class Throttle
    getter :name, :limit, :period, :block

    def initialize(@name : String, @limit : Int32, @period : Int32, &@block : (HTTP::Request) -> String?)
    end

    def matched_by?(request : HTTP::Request) : Bool
      discriminator = block.call(request)
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
