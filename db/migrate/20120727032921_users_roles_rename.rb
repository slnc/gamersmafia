class UsersRolesRename < ActiveRecord::Migration
  def up
    User.db_query("alter table users_roles rename to users_skills;")
  end

  def down
  end
end
