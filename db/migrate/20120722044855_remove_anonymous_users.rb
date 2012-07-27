class RemoveAnonymousUsers < ActiveRecord::Migration
  def up
    User.db_query("DROP TABLE anonymous_users;")
  end

  def down
  end
end
