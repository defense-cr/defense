module Defense
  abstract class Store
    abstract def increment(key : String, expires_in : Int32) : Int64
    abstract def reset

    def prefix
      "defense"
    end
  end
end
