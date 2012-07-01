class ClansUpdatedOn < ActiveRecord::Migration
  def up
    User.db_query(
        "ALTER TABLE clans ADD column updated_on timestamp not null default now()")
  end

  def down
  end
end
