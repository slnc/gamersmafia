# -*- encoding : utf-8 -*-
class RemoveUnusedFactionAttributes < ActiveRecord::Migration
  def up
    User.db_query("ALTER TABLE factions DROP COLUMN boss_user_id")
    User.db_query("ALTER TABLE factions DROP COLUMN underboss_user_id")
  end

  def down
  end
end
