class AtomicModeration < ActiveRecord::Migration
  def up
    User.db_query("ALTER TABLE comments ADD COLUMN moderation_reason smallint;")
  end

  def down
  end
end
