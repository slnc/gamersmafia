class MigrateSuv < ActiveRecord::Migration
  def up
    User.find_each(:conditions => "id IN (SELECT distinct(user_id) FROM contents WHERE karma_points > 0)") do |u|

      UserEmblemObserver.check_suv(u)
    end
    User.find_each(:conditions => "id IN (SELECT distinct(user_id) FROM contents WHERE state = 2)") do |u|
      Emblems.give_emblem_if_not_present(u, "first_content")
    end
  end

  def down
  end
end
