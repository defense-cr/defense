module Defense
  abstract class Store
    abstract def increment(key : String, expires_in : Int32) : Int32
  end
end
