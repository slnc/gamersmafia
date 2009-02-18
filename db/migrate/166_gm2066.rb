class Gm2066 < ActiveRecord::Migration
  def self.up
    GmSys.command("find #{FRAGMENT_CACHE_PATH}/common/globalnavbar/ -type f -exec rm {} \\\;")
  end

  def self.down
  end
end
