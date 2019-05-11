module Defense
  class Fail2Ban
    def self.filter(discriminator, maxretry = 0, findtime = 0, bantime = 0) : Bool
      filter = false
      if store.exists("#{prefix}:ban:#{discriminator}")
        filter = true
      elsif yield
        filter = true
      end
      filter
    end

    private def self.store
      Defense.store
    end

    private def self.prefix
      "fail2ban"
    end
  end
end
