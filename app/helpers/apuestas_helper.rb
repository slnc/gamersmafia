# -*- encoding : utf-8 -*-
module ApuestasHelper
  GM_KEY = "%gm"
  MIN_BETS_PREDICTION_RANKING = 15

  def bet_open_message(bet)
    if bet.closes_on > Time.now
      <<-EOD
      Las apuestas para esta partida se cierran en
      <br />
      <div class="centered">
        <strong>#{format_interval(bet.closes_on.to_i - Time.now.to_i)}</strong>
      </div>
      EOD
    else
      "La partida está en curso o finalizada, ya no se permiten las apuestas."
    end
  end

  def bets_prediction_ranking
    accuracy_table = {}
    # Get top ranked individuals' score
    User.db_query(
      "SELECT (SUM(played_bets_correctly_predicted)::float /
               SUM(played_bets_participation)) AS accuracy,
              user_id,
              SUM(played_bets_correctly_predicted) AS
                played_bets_correctly_predicted,
              SUM(played_bets_participation) AS played_bets_participation
         FROM stats.users_daily_stats
        WHERE played_bets_participation > 0
          AND created_on >= now() - '90 days'::interval
        GROUP BY user_id
        HAVING SUM(played_bets_participation) >= #{MIN_BETS_PREDICTION_RANKING}
      ORDER BY accuracy DESC LIMIT 10").each do |db_row|
        accuracy_table[db_row["user_id"].to_i] = [
            db_row["accuracy"].to_f, db_row["played_bets_participation"].to_i]
    end
    user_ids = accuracy_table.keys

    # Get GM score
    gm_results = User.db_query(
        "SELECT (SUM(played_bets_crowd_correctly_predicted)::float /
                 SUM(played_bets_participation)) as accuracy,
                 SUM(played_bets_crowd_correctly_predicted),
                 SUM(played_bets_participation) as played_bets_participation
           FROM stats.general
          WHERE played_bets_participation > 0
          AND created_on >= now() - '90 days'::interval
          ")
    if gm_results.size == 0
      return []
    end
    accuracy_table[ApuestasHelper::GM_KEY] = [
        gm_results[0]["accuracy"].to_f,
        gm_results[0]["played_bets_participation"].to_i]

    # Build the rank
    key = accuracy_table.keys.last
    ranking = accuracy_table.sort_by {|user_id, data| data[0]}
    ranking.reverse!
    user_ids_to_user = {}
    User.find(:all, :conditions => ["id IN (?)", user_ids]).each do |user|
      user_ids_to_user[user.id] = user
    end

    ranking.collect {|user_id, score, bets|
      if user_id == ApuestasHelper::GM_KEY
        [user_id, score, bets]
      else
        [user_ids_to_user[user_id], score, bets]
      end
    }
  end
end
