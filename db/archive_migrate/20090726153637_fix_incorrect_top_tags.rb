class FixIncorrectTopTags < ActiveRecord::Migration
  def self.up
    Content.find(:all, :conditions => "id IN (SELECT distinct(content_id) FROM users_contents_tags)").each do |c|
      UsersContentsTag.recalculate_content_top_tags(c)
    end
  end

  def self.down
  end
end
