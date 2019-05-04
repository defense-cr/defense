module Defense
  abstract class Store
    abstract def has_key?(key : String) : Bool
    abstract def increment(key : String, expires_in : Int32) : Int64
    abstract def keys : Array(String)
    abstract def reset

    def prefix
      "defense"
    end
  end
end
