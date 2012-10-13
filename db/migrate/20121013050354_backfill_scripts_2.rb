class BackfillScripts2 < ActiveRecord::Migration
  def up
    puts "Comments Valorations.."
    cvts = CommentsValorationsType.find_positive
    User.find_each(
        :conditions => "id IN (
            SELECT DISTINCT(user_id)
            FROM comments
            WHERE id IN (
              SELECT distinct(comment_id)
              from comments_valorations
              where comments_valorations_type_id IN (2, 3, 4, 8)))") do |u|
      cvts.each do |cvt|
        UserEmblemObserver::Emblems.comments_valorations_receiver(cvt, u)
      end
    end
  end

  def down
  end
end
