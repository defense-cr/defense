module Defense
  abstract class Store
    abstract def exists?(unprefixed_key : String) : Bool
    abstract def increment(unprefixed_key : String, expires_in : Int32) : Int64
    abstract def read(unprefixed_key : String) : Int64 | Nil
    abstract def reset

    def prefix
      "defense"
    end

    def prefix_key(unprefixed_key : String) : String
      "#{prefix}:#{unprefixed_key}"
    end
  end
end
