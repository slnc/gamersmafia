# -*- encoding : utf-8 -*-
module Gmstats
  def self.cash_in_time_period(t1, t2)
    injected = User.db_query("select sum(ammount) from cash_movements where object_id_from_class is null AND created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")[0]['sum'].to_f
    removed = User.db_query("select sum(ammount) from cash_movements where object_id_to_class is null AND created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")[0]['sum'].to_f
    injected - removed
  end

  def self.karma_in_time_period(t1, t2)
    Karma.karma_in_time_period(t1, t2)
  end

  def self.faction_karma_in_time_period(faction, t1, t2)
    Karma.faction_karma_in_time_period(faction, t1, t2)
  end



  def self.comments_created_in_time_period(t1, t2)
    # results = {}
    #Comment.db_query("SELECT count(id), date_trunc('day', created_on)
    #                    FROM comments
    #                WHERE created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'
    #                GROUP BY date_trunc('day', created_on)
    #                ORDER BY date_trunc('day', created_on) ASC").each { |dbr| results[dbr['date_trunc']] = dbr['count'].to_i }
    # results
    Comment.db_query("SELECT count(id) FROM comments
                    WHERE deleted = \'f\' AND created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")[0]['count']
  end

  def self.refered_hits_in_time_period(t1, t2)
    User.db_query("SELECT count(*) FROM refered_hits
                    WHERE created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")[0]['count']
  end

  def self.users(state, time)
    states = {:total => '',
      :confirmed => "state <> #{User::ST_UNCONFIRMED}",
      :active => "state = #{User::ST_ACTIVE}",
      :zombie => "state = #{User::ST_ZOMBIE}",
      :shadow => "state = #{User::ST_SHADOW}",
      :resurrected => "state = #{User::ST_RESURRECTED}",
      :unconfirmed => "state = #{User::ST_UNCONFIRMED}",
      :unconfirmed_1w => "state = #{User::ST_UNCONFIRMED_1W}",
      :unconfirmed_2w => "state = #{User::ST_UNCONFIRMED_2W}",
      :banned => "state = #{User::ST_BANNED}",
      :deleted => "state = #{User::ST_DELETED}",
      :disabled => "state = #{User::ST_DISABLED}"}

    qcond = (states[state] == '') ? "" : "#{states[state]} AND "
    qcond<< "created_on <= '#{time.strftime('%Y-%m-%d %H:%M:%S')}'"
    User.count(:conditions => qcond)
  end
end
