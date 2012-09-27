module Ias
  VALID_IAS = %w(
    jabba
    MrAlariko
    MrAchmed
    MrCheater
    MrMan
    nagato
  )

  @@cache_ias = {}
  def self.ia(login)
    @@cache_ias[login] ||= User.find(
        :first, :conditions => ["login = ? AND is_bot IS TRUE", login])
  end

  def self.method_missing(method_name)
    if !VALID_IAS.include?(method_name.to_s)
      raise "Invalid IA name #{method_name}"
    end

    self.ia(method_name)
  end
end
