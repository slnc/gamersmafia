class Rmbetscaches < ActiveRecord::Migration
  def self.up
    GmSys.command("/*/home/index/apuestas_")
    GmSys.command("find #{FRAGMENT_CACHE_PATH}/home/index/ -type f -mmin +2 -exec rm {} \\\;")
  end

  def self.down
  end
end
