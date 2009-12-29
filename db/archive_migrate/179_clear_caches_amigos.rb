class ClearCachesAmigos < ActiveRecord::Migration
  def self.up
    GmSys.command("find #{FRAGMENT_CACHE_PATH}/common/miembros/*/* -name \*amigos.cache -type f +mmin -14440 -exec rm {} \\\;")
  end

  def self.down
  end
end
