module Defense
  class MemoryStore < Store
    def initialize
      @data = Hash(String, Hash(String, Int64)).new
    end

    def increment(unprefixed_key : String, expires_in : Int32) : Int64
      current_time = Time.utc.to_unix_ms

      key = "#{prefix}:#{unprefixed_key}"

      if @data[key]? && @data[key]["expires_at"] > current_time
        @data[key]["count"] += 1
      else
        @data[key] = { "count" => 1i64, "expires_at" => (current_time + expires_in * 1000) }
      end

      @data[key]["count"]
    end

    def reset
      @data.clear
    end
  end
end
