class AlterCreatedOnUsersEmblems < ActiveRecord::Migration
  def up
    execute "alter table users_emblems alter created_on type timestamp;"
  end

  def down
  end
end
