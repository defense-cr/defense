module Defense
  class Fail2Ban
    def self.filter(discriminator, maxretry = 0, findtime = 0, bantime = 0) : Bool
      filter = false
      if banned?(discriminator)
        filter = true
      elsif yield
        count = store.increment("#{prefix}:count:#{discriminator}", findtime)
        if count >= maxretry
          store.increment("#{prefix}:ban:#{discriminator}", bantime)
        end
        filter = true
      end
      filter
    end


    private def self.banned?(discriminator : String) : Bool
      store.exists("#{prefix}:ban:#{discriminator}")
    end

    private def self.store
      Defense.store
    end

    private def self.prefix
      "fail2ban"
    end
  end
end
