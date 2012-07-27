class AddHiddenStateToComment < ActiveRecord::Migration
  def change
    User.db_query(
        "ALTER TABLE comments ADD column state smallint NOT NULL default 0")
  end
end
