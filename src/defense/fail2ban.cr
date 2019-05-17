module Defense
  class Fail2Ban
    def self.filter(discriminator : String, maxretry : Int32 = 0, findtime : Int32 = 0, bantime : Int32 = 0) : Bool
      if banned?(discriminator)
        true
      elsif yield
        fail!(discriminator, maxretry, findtime, bantime)
      else
        false
      end
    end

    private def self.banned?(discriminator : String) : Bool
      store.exists?("#{prefix}:ban:#{discriminator}")
    end

    private def self.fail!(discriminator : String, maxretry : Int32, findtime : Int32, bantime : Int32) : Bool
      count = store.increment("#{prefix}:count:#{discriminator}", findtime)

      if count >= maxretry
        ban!(discriminator, bantime)
      end

      true
    end

    private def self.ban!(discriminator : String, bantime : Int32)
      store.increment("#{prefix}:ban:#{discriminator}", bantime)
    end

    private def self.store
      Defense.store
    end

    private def self.prefix
      "fail2ban"
    end
  end
end
