module Defense
  class MemoryStore < Store
    def initialize
      @data = Hash(String, Int32).new # how to represent the time?!
    end

    def increment(key : String, expires_in : Int32) : Int32
      # check that it's not expired
      # if expired => reset
      @data[key] = (@data[key]? || 0) + 1
    end

    def reset
      @data.clear
    end
  end
end
