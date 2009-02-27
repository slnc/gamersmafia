module Gmstats
  def self.cash_in_time_period(t1, t2)
    injected = User.db_query("select sum(ammount) from cash_movements where object_id_from_class is null AND created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")[0]['sum'].to_f
    removed = User.db_query("select sum(ammount) from cash_movements where object_id_to_class is null AND created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")[0]['sum'].to_f
    injected - removed
  end
  
  def self.karma_in_time_period(t1, t2)
    points = 0
    cond = { :conditions => "deleted = 'f' AND created_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'" }
    cond_content = { :conditions => "state = #{Cms::PUBLISHED} AND created_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'" }    
    points += Comment.count(cond) * Karma::KPS_CREATE['Comment']
    points += Blogentry.count(cond_content) * Karma::KPS_CREATE['Blogentry']
    points += Topic.count(cond_content) * Karma::KPS_CREATE['Topic']
    points += Question.count(cond_content) * Karma::KPS_CREATE['Question']
    
    for c in Cms::contents_classes_publishable
      # author of
      points += c.count(cond_content) * Karma::KPS_CREATE[c.name]
      points += c.count(:conditions => "state = #{Cms::PUBLISHED} AND created_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}' and approved_by_user_id is not null") * Karma::KPS_SAVE[c.name] # legacy
    end
    
    points
  end
  
  def self.faith_in_time_period(t1, t2)
    total = 0
    total += Faith::FPS_ACTIONS['registration'] * User.count(:conditions => "state <> #{User::ST_UNCONFIRMED} AND referer_user_id is not null AND created_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")
    total += Faith::FPS_ACTIONS['resurrection'] * User.count(:conditions => "state <> #{User::ST_UNCONFIRMED} AND coalesce(referer_user_id, 0) <> resurrected_by_user_id and resurrected_by_user_id is not null AND created_on < '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND lastseen_on > '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND resurrection_started_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")
    total += Faith::FPS_ACTIONS['resurrection_own'] * User.count(:conditions => "state <> #{User::ST_UNCONFIRMED} AND coalesce(referer_user_id, 0) = resurrected_by_user_id and resurrected_by_user_id is not null AND created_on < '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND lastseen_on > '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND resurrection_started_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")
    total += Faith::FPS_ACTIONS['rating'] * ContentRating.count(:conditions => "created_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")
    total += Faith::FPS_ACTIONS['publishing_decision'] * PublishingDecision.count(:conditions => "created_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")
    total += Faith::FPS_ACTIONS['competitions_match'] * CompetitionsMatch.count(:conditions => "#{Competition::COMPLETED_ON_SQL} and completed_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")
    total += Faith::FPS_ACTIONS['hit'] * User.db_query("SELECT count(*) FROM refered_hits WHERE created_on between '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")[0]['count'].to_i
    total
  end
  
  def self.faction_karma_in_time_period(faction, t1, t2)
    k = 0
    root_term = Term.single_toplevel(faction.referenced_thing_field => faction.referenced_thing.id)
    Cms::CONTENTS_WITH_CATEGORIES.each do |cls_name|
      k += root_term.contents_count(cls_name, :conditions => "state = #{Cms::PUBLISHED} AND #{Inflector.underscore(c.name)}_id in (#{cat_ids.join(',')}) AND created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'") * Karma::KPS_CREATE[c.items_class.name]
    end
    k
  end
  # TODO falta karma por comentarios
  
  
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
