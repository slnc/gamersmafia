class UsersEmblemsBackfill < ActiveRecord::Migration
  def up
    User.db_query("UPDATE users set emblems_mask = '';")
    User.db_query("DELETE FROM users_emblems")
    User.find_each(:conditions => "comments_count >= 50") do |user|
      UserEmblemObserver::Emblems.comments_count(user)
    end
  end

  def down
  end
end
