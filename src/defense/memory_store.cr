module Defense
  class MemoryStore < Store
    def initialize
      @data = Hash(String, Int64).new
    end

    def increment(key : String, expires_in : Int32) : Int64
      # check that it's not expired
      # if expired => reset
      @data[key] = (@data[key]? || 0i64) + 1i64
    end

    def reset
      @data.clear
    end
  end
end
