require File.dirname(__FILE__) + '/../../../test/test_helper'

class PopularityTest < Test::Unit::TestCase   
  def test_update_ranking_users_users
    User.db_query("INSERT INTO stats.users_daily_stats (created_on, user_id, popularity) VALUES(now() - '1 day'::interval, 1, 1)")
    Popularity.update_ranking_users
    assert_equal 1, User.find(1).ranking_popularity_pos
    assert_equal 2, User.find(2).ranking_popularity_pos
  end
  
    def test_update_ranking_clans
    User.db_query("INSERT INTO stats.clans_daily_stats (created_on, clan_id, popularity) VALUES(now() - '1 day'::interval, 1, 1)")
    Popularity.update_ranking_clans
    assert_equal 1, Clan.find(1).ranking_popularity_pos
    assert_equal 2, Clan.find(2).ranking_popularity_pos
  end
end
