class FixClanesCaches < ActiveRecord::Migration
  def up
    User.db_query(
        "ALTER TABLE global_vars ADD COLUMN clans_updated_on timestamp")
  end

  def down
  end
end
