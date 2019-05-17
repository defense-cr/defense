module Defense
  class MemoryStore < Store
    def initialize
      @data = Hash(String, Hash(String, Int64)).new
    end

    def increment(unprefixed_key : String, expires_in : Int32) : Int64
      current_time = Time.utc.to_unix_ms

      key = prefix_key(unprefixed_key)

      if exists?(unprefixed_key)
        @data[key]["count"] += 1
      else
        @data[key] = {"count" => 1i64, "expires_at" => (current_time + expires_in * 1000)}
      end

      @data[key]["count"]
    end

    def exists?(unprefixed_key : String) : Bool
      key = prefix_key(unprefixed_key)
      @data.has_key?(key) && @data[key]["expires_at"] > Time.utc.to_unix_ms
    end

    def read(unprefixed_key : String) : Int64 | Nil
      if exists?(unprefixed_key)
        @data[prefix_key(unprefixed_key)]["count"]
      end
    end

    def reset
      @data.clear
    end
  end
end
