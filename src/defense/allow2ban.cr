module Defense
  class Allow2Ban < Fail2Ban
    private def self.fail!(discriminator : String, maxretry : Int32, findtime : Int32, bantime : Int32) : Bool
      count = store.increment("#{prefix}:count:#{discriminator}", findtime)

      if count >= maxretry
        ban!(discriminator, bantime)
      end

      false
    end

    private def self.prefix
      "allow2ban"
    end
  end
end
