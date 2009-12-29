class DelFragmentCaches < ActiveRecord::Migration
  def self.up
    GmSys.command("find #{FRAGMENT_CACHE_PATH}/ -type f -mmin -20160 -exec rm {} \\\;")
  end

  def self.down
  end
end
