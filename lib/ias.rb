module Ias
  # Apply everywhere where we call Nagato or any other bot

  @@cache_ias = {}
  def self.ia(login)
    @@cache_ias[login] ||= User.find(
        :first, :conditions => ["login = ? AND is_bot IS TRUE", login])
  end

  def self.MrAlariko
    self.ia("MrAlariko")
  end

  def self.MrAchmed
    self.ia("MrAchmed")
  end

  def self.MrCheater
    self.ia("MrCheater")
  end

  def self.MrMan
    self.ia("MrCheater")
  end

  def self.nagato
    self.ia("nagato")
  end
end
