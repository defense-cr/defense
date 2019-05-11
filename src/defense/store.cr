module Defense
  abstract class Store
    abstract def exists(unprefixed_key  : String) : Bool
    abstract def increment(unprefixed_key : String, expires_in : Int32) : Int64
    abstract def read(key : String) : Int32 | String | Nil
    abstract def reset

    def prefix
      "defense"
    end
  end
end
