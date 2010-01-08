class TagsNowGiveFaith < ActiveRecord::Migration
  def self.up
    User.can_login.find(:all, :conditions => "id IN (select distinct(user_id) from users_contents_tags)").each do |u|
      u.cache_faith_points = nil
      u.faith_points
    end
  end

  def self.down
  end
end
