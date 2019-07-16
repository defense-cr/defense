module Defense
  private class Safelist
    getter :name, :block

    def initialize(@name : String, &@block : (HTTP::Request) -> Bool)
    end

    def matched_by?(request : HTTP::Request) : Bool
      block.call(request)
    end
  end
end
