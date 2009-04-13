module PrePlugins
  @_prePluginsRun ||= false
  if !@_prePluginsRun
    require "#{RAILS_ROOT}/lib/bank.rb"
    ActiveRecord::Base.send(:include, Bank::Has::BankAccount)
    ActiveRecord::Base.send(:include, Bank::Has::BankAmmountFromUser)
    @_prePluginsRun = true
  end
end
