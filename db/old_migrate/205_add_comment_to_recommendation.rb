class AddCommentToRecommendation < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table contents_recommendations add column comment varchar;"
  end

  def self.down
  end
end
