module ApuestasHelper
  GM_KEY = "%gm"

  def bets_prediction_ranking
    accuracy_table = {}
    # Get top ranked individuals' score
    User.db_query(
      "SELECT (SUM(played_bets_correctly_predicted)::float /
               SUM(played_bets_participation)) AS accuracy,
              user_id
         FROM stats.users_daily_stats
        WHERE played_bets_participation > 0
        GROUP BY user_id
        HAVING SUM(played_bets_participation) >= 10
      ORDER BY accuracy DESC LIMIT 10").each do |db_row|
        accuracy_table[db_row["user_id"].to_i] = db_row["accuracy"].to_f
    end
    user_ids = accuracy_table.keys

    # Get GM score
    gm_results = User.db_query(
        "SELECT (played_bets_crowd_correctly_predicted::float /
                 played_bets_participation) as accuracy
           FROM stats.general
       ORDER BY created_on DESC
          LIMIT 1")
    if gm_results.size == 0
      return []
    end
    accuracy_table[ApuestasHelper::GM_KEY] = gm_results[0]["accuracy"].to_f

    # Build the rank
    ranking = accuracy_table.sort_by {|user_id, score| score}
    ranking.reverse!
    user_ids_to_user = {}
    User.find(:all, :conditions => ["id IN (?)", user_ids]).each do |user|
      user_ids_to_user[user.id] = user
    end

    ranking.collect {|user_id, score|
      if user_id == ApuestasHelper::GM_KEY
        [user_id, score]
      else
        [user_ids_to_user[user_id], score]
      end
    }
  end
end
