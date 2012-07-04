require 'test_helper'

class ApuestasHelperTest < ActionView::TestCase

  test "bets_prediction_ranking" do
    User.db_query(
      "INSERT INTO stats.users_daily_stats (created_on,
                                            user_id,
                                            played_bets_correctly_predicted,
                                            played_bets_participation)
            VALUES (NOW(), 1, 50, 100)")

    User.db_query(
      "INSERT INTO stats.users_daily_stats (created_on,
                                            user_id,
                                            played_bets_correctly_predicted,
                                            played_bets_participation)
            VALUES (NOW(), 3, 25, 100)")

    User.db_query(
      "INSERT INTO stats.general (created_on,
                                  played_bets_crowd_correctly_predicted,
                                  played_bets_participation)
            VALUES (NOW(), 20, 200)")

    expected = [
      [1, 0.5],
      [3, 0.25],
      ["%gm", 0.1],
    ]

    out = bets_prediction_ranking.collect {|user, score|
      [user.kind_of?(User) ? user.id : user, score]
    }
    assert_equal expected, out
  end
end
