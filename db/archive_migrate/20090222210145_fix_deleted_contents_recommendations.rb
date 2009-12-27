class FixDeletedContentsRecommendations < ActiveRecord::Migration
  def self.up
    execute "delete from contents_recommendations where content_id in (select id from contents where state <> 2);"
  end

  def self.down
  end
end
