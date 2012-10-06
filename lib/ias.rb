module Ias
  VALID_IAS = %w(
    jabba
    mralariko
    mrachmed
    mrcheater
    mrgod
    mrman
    nagato
  )

  @@cache_ias = {}
  def self.ia(login)
    @@cache_ias[login] ||= User.find(
        :first, :conditions => ["login = ?", login])
  end

  def self.method_missing(method_name)
    if !VALID_IAS.include?(method_name.downcase.to_s)
      raise "Invalid IA name #{method_name}"
    end

    self.ia(method_name)
  end
end
