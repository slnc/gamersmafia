class FixDemosAndBetsPortal < ActiveRecord::Migration
  def self.up
    # User.db_query("UPDATE contents SET url = NULL WHERE content_type_id IN (15, 23);")
  end

  def self.down
  end
end
