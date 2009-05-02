# VALORACIONES POR NIVEL
# - Anónimos: 1 contenidos al día
# - Nivels Iniciado: 5 contenidos al día
# - Nivel Adepto de Fe: 10 contenidos al día
# - Nivel Chamán de Fe: 15 contenidos al día
# - Nivel Sumo Sacerdote de Fe: 20 contenidos al día
# - Nivel Semi-Dios de Fe: 25 contenidos al día 
# 
# DENOMINACIONES
# Nivel 0: Iniciado 
# Nivel 1: Adepto           500
# Nivel 2: Chamán          5500
# Nivel 3: Sumo Sacerdote 60500
# Nivel 4: Semi-Dios     160325
# Nivel 5: Dios          300000
module Faith
  POINTS_PER_LEVEL = [0, 500, 5500, 60500, 160325, 300000, 600000, 900000]
  
  FPS_ACTIONS = {
      'registration' => 100, 
      'resurrection' => 100,
      'resurrection_own' => 75,
      'rating' => 5,
      'publishing_decision' => 5,
      'competitions_match' => 25,
      'hit' => 1,
    # TODO no añadir competiciones hasta que diferenciemos entre ganar por forfeit y ganar
  }
  
  CODES = {
    0 => 'initiated',
    1 => 'adept',
    2 => 'shaman',
    3 => 'high_priest',
    4 => 'half_god',
    5 => 'god'}
  
  NAMES = {
    0 => 'Iniciado',
    1 => 'Adepto',
    2 => 'Chamán',
    3 => 'Sumo Sacerdote',
    4 => 'Semi-Dios',
    5 => 'Dios'}
  
  def self.kp_for_level(level)
    POINTS_PER_LEVEL[level]
  end
  
  def self.pc_done_for_next_level(kp)
    cur_level = Faith.level(kp)
    kp_cur_lvl  = Faith.kp_for_level(cur_level)
    kp_next_lvl = Faith.kp_for_level(cur_level + 1)
    
    diff_100 = kp_next_lvl - kp_cur_lvl
    diff_done = kp - kp_cur_lvl
    
    return (100 * diff_done / diff_100).to_i
  end
  
  def self.level(kp)
    # Hacemos la búsqueda de arriba abajo ya que lo más normal será que los niveles sean bajos
    kp = kp.faith_points unless kp.is_a?(Fixnum)
    i = 0
    POINTS_PER_LEVEL.each do |level_points|
      break if kp < level_points
      i += 1
    end
    i - 1
  end
  
  def self.faith_points_of_users_at_date_range(date_start, date_end)
    date_start, date_end = date_end, date_start if date_start > date_end
    created_on_sql = "created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'"
    points = {}
    
    # registrations_active
    User.db_query("SELECT count(*), referer_user_id 
                     FROM users
                    WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')}) and lastseen_on >= now() - '3 months'::interval AND referer_user_id IS NOT NULL
                 GROUP BY referer_user_id").each do |dbc|
      points[dbc['referer_user_id']] ||= 0
      points[dbc['referer_user_id']] += dbc['count'].to_i * Faith::FPS_ACTIONS['registration']
    end
    
    # resurrections_active
    User.db_query("SELECT count(*),  resurrected_by_user_id
                     FROM users
                    WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')}) and (resurrected_by_user_id <> referer_user_id OR referer_user_id IS NULL) and resurrected_by_user_id IS NOT NULL and lastseen_on > now() - '3 months'::interval
                 GROUP BY resurrected_by_user_id").each do |dbc|
      points[dbc['resurrected_by_user_id']] ||= 0
      points[dbc['resurrected_by_user_id']] += dbc['count'].to_i * Faith::FPS_ACTIONS['resurrection']
    end
    
    # resurrections_own_active
    User.db_query("SELECT count(*), resurrected_by_user_id 
                     FROM users
                    WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')}) and resurrected_by_user_id = referer_user_id and resurrected_by_user_id IS NOT NULL and lastseen_on > now() - '3 months'::interval
                 GROUP BY resurrected_by_user_id").each do |dbc|
      points[dbc['resurrected_by_user_id']] ||= 0
      points[dbc['resurrected_by_user_id']] += dbc['count'].to_i * Faith::FPS_ACTIONS['resurrection_own']
    end
    
    # hits
    User.db_query("SELECT count(*), 
                          user_id 
                     FROM refered_hits 
                    WHERE #{created_on_sql}
                 GROUP BY user_id").each do |dbc|
      points[dbc['user_id']] ||= 0
      points[dbc['user_id']] += dbc['count'].to_i * Faith::FPS_ACTIONS['hit']
    end
    
    # publishing_decisions
    User.db_query("SELECT count(*), 
                          user_id 
                     FROM publishing_decisions 
                    WHERE #{created_on_sql}
                      AND #{PublishingDecision::VALID_SQL}
                      AND (select is_bot FROM users WHERE id = user_id) = 'f'
                 GROUP BY user_id").each do |dbc|
      points[dbc['user_id']] ||= 0
      points[dbc['user_id']] += dbc['count'].to_i * Faith::FPS_ACTIONS['publishing_decision']
    end
    
    # contents_ratings
    User.db_query("SELECT count(*), 
                          user_id 
                     FROM content_ratings 
                    WHERE #{created_on_sql}
                 GROUP BY user_id").each do |dbc|
      points[dbc['user_id']] ||= 0
      points[dbc['user_id']] += dbc['count'].to_i * Faith::FPS_ACTIONS['rating']
    end
    
    # comments_valorations
    User.db_query("SELECT count(*), 
                          user_id 
                     FROM comments_valorations 
                    WHERE #{created_on_sql}
                 GROUP BY user_id").each do |dbc|
      points[dbc['user_id']] ||= 0
      points[dbc['user_id']] += dbc['count'].to_i * Faith::FPS_ACTIONS['rating']
    end
    
    # competition_matches
    CompetitionsMatch.find(:all, :conditions => "#{Competition::COMPLETED_ON_SQL} AND completed_on >= now() - '1 week'::interval").each do |cm|
      [cm.participant1, cm.participant2].each do |participant|
        next if participant.nil?
        participant.users.each do |u|
          points[u.id.to_s] ||= 0
          points[u.id.to_s] += Faith::FPS_ACTIONS['competitions_match']
        end
      end
    end
    
    points
  end
  
  def self.calculate_faith_points(user)
    # ACTUALIZAR la de arriba si ésta se cambia
    points = 0
    points += Faith.registrations_active(user) * Faith::FPS_ACTIONS['registration']
    points += Faith.resurrections_active(user) * Faith::FPS_ACTIONS['resurrection']
    points += Faith.resurrections_own_active(user) * Faith::FPS_ACTIONS['resurrection_own']
    points += Faith.hits(user) * Faith::FPS_ACTIONS['hit']
    points += Faith.publishing_decisions(user) * Faith::FPS_ACTIONS['publishing_decision']
    points += user.content_ratings.count * Faith::FPS_ACTIONS['rating']
    points += user.comments_valorations.count * Faith::FPS_ACTIONS['rating']
    points += Competitions.count_all_matches_from_user(user, Competition::COMPLETED_ON_SQL) * Faith::FPS_ACTIONS['competitions_match']
    points
  end
  
  def self.publishing_decisions(user)
    PublishingDecision.count(:conditions => ["#{PublishingDecision::VALID_SQL} AND user_id = ?", user.id]) # contamos tanto las que todavía no se han asentado como las que ya sabemos que están right
  end
  
  def self.registrations_active(user)
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and lastseen_on >= now() - '3 months'::interval and referer_user_id = ?", user.id])
  end
  
  def self.registrations_inactive(user)
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and lastseen_on < now() - '3 months'::interval and referer_user_id = ?", user.id])
  end
  
  def self.registrations_total(user)
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and referer_user_id = ?", user.id])
  end
  
  def self.resurrections_own_active(user)
    # TODO tests
    #      puts User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and referer_user_id = ? and resurrected_by_user_id = ? and lastseen_on < now() - \'3 months\'::interval', user.id, user.id])
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and referer_user_id = ? and resurrected_by_user_id = ? and lastseen_on > now() - '3 months'::interval", user.id, user.id])
  end
  
  def self.resurrections_own_inactive(user)
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and referer_user_id = ? and resurrected_by_user_id = ? and lastseen_on < now() - '3 months'::interval", user.id, user.id])
  end
  
  def self.resurrections_own_total(user)
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and referer_user_id = ? and resurrected_by_user_id = ?", user.id, user.id])
  end
  
  def self.resurrections_active(user)
    # resurrecciones activas de usuarios no referidos por mi
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and COALESCE(referer_user_id, 0) <> ? and resurrected_by_user_id = ? and lastseen_on >= now() - '3 months'::interval", user.id, user.id])
  end
  
  def self.resurrections_inactive(user)
    # resurrecciones inactivas de usuarios no referidos por mi
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and COALESCE(referer_user_id, 0) <> ? and resurrected_by_user_id = ? and lastseen_on > now() - '3 months'::interval", user.id, user.id])
  end
  
  def self.resurrections_total(user)
    # resurrecciones de usuarios no referidos por mi
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and COALESCE(referer_user_id, 0) <> ? and resurrected_by_user_id = ?", user.id, user.id])
  end
  
  def self.resurrections_incomplete(user)
    # resurrecciones inactivas de usuarios no referidos por mi
    User.count(:conditions => ["state IN (#{User::STATES_CAN_LOGIN.join(',')}) and resurrected_by_user_id = ? and resurrection_started_on > now() - '7 days'::interval and lastseen_on < now() - '3 months'::interval", user.id])
  end
  
  def self.competitions_matches(user)
    total = 0
    Competition.find_related_with_user(user.id).each { |c|
      p = c.get_active_participant_for_user(user) # TODO si un usuario pertenece a más de un clan apuntado al mismo torneo esto no será correcto
      total += c.matches(:completed, :participant => p, :forfeit => false, :count => true) if p
    }
    total
  end
  
  def self.hits(user)
    User.db_query("SELECT count(user_id) FROM refered_hits WHERE user_id = #{user.id}")[0]['count'].to_i
  end
  
  def self.max_incomplete_resurrections(user)
   (Faith.level(user.faith_points) + 1) * 5
  end
  
  def self.max_daily_ratings(user)
    ratings = (Faith.level(user.faith_points) + 1) * 5
  end
  
  
  def self.max_user_points
    User.db_query("SELECT max(cache_faith_points) FROM users")[0]['max'].to_i
  end
  
  
  # TODO aplicar este método de dar puntos de fe a toda la app
  def self.give(user, points)
    raise TypeError unless user.kind_of?(User)
    raise TypeError unless points.kind_of?(Fixnum)
    raise ValueError unless points > 0
    
    user.faith_points # forzamos el cálculo desde 0, esto sí que puede incurrir en race condition
    user.cache_faith_points = User.db_query("UPDATE users SET cache_faith_points = cache_faith_points + #{points} WHERE id = #{user.id}; SELECT cache_faith_points FROM users WHERE id = #{user.id}")[0]['cache_faith_points']
  end
  
  def self.take(user, points)
    raise TypeError unless user.kind_of?(User)
    raise TypeError unless points.kind_of?(Fixnum)
    raise ValueError unless points > 0
    user.faith_points # forzamos el cálculo desde 0, esto sí que puede incurrir en race condition
    user.cache_faith_points = User.db_query("UPDATE users SET cache_faith_points = cache_faith_points - #{points} WHERE id = #{user.id}; SELECT cache_faith_points FROM users WHERE id = #{user.id}")[0]['cache_faith_points']
  end
  
  def self.reset(user)
    raise TypeError unless user.kind_of?(User)
    User.db_query("UPDATE users SET cache_faith_points = null WHERE id = #{user.id}")
    user.cache_faith_points = nil
  end
  
  def self.ranking_user(u)
    # contamos incluso los que tienen 0
    ucount = User.db_query("SELECT count(*) FROM users WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')})")[0]['count'].to_i
    pos = u.ranking_faith_pos ? u.ranking_faith_pos : ucount 
    {:pos => pos, :total => ucount }
  end
  
  def self.update_ranking
    lista = {} 
    User.db_query("SELECT id, cache_faith_points FROM users WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')})").each do |dbr|
      lista[dbr['cache_faith_points'].to_i] ||= []
      lista[dbr['cache_faith_points'].to_i] << dbr['id'].to_i
    end
    
    pos = 1
    lista.keys.sort.reverse.each do |k|
      # en caso de empate los ids menores (mas antiguos) tienen preferencia
      lista[k].sort.each do |uid|
        User.db_query("UPDATE users SET ranking_faith_pos = #{pos} WHERE id = #{uid}")
        pos += 1
      end
    end
  end
  
  def self.faith_points_of_users_at_date_range(date_start, date_end)
    date_start, date_end = date_end, date_start if date_start > date_end
    points = {}
    
    # BUG es imposible contabilizar las resurrecciones pasadas correctamente
    # BUG para las resurrecciones activas ademas si no han visitado la web el dia de contabilizar stats no dan fe, aqui caducan antes de 3 meses
    [['refered_hits', 'hit'], 
    ['publishing_decisions', 'publishing_decision'], 
    ['content_ratings', 'rating'], 
    ['comments_valorations', 'rating'],
    ['users', 'registration', 'referer_user_id IS NOT NULL AND lastseen_on >= now() - \'3 months\'::interval ', 'referer_user_id'],
    ['users', 'resurrection', 'resurrected_by_user_id IS NOT NULL AND refered_user_id <> resurrected_by_user_id', 'resurrected_by_user_id', 'lastseen_on'],
    ['users', 'resurrection_own', 'resurrected_by_user_id IS NOT NULL AND refered_user_id = resurrected_by_user_id', 'resurrected_by_user_id', 'lastseen_on'],
    ].each do |tinfo|
      tbl_name = tinfo[0]
      attr_info = tinfo[1]
      additional_and = (tinfo.size >= 3) ? " AND #{tinfo[2]}" : ''
      group_by = (tinfo.size >= 4) ? tinfo[3] : 'user_id'
      date_field = (tinfo.size >= 5) ? tinfo[4] : 'created_on'
      User.db_query("SELECT count(*), 
                            #{group_by}
                     FROM #{tbl_name} 
                    WHERE #{date_field} BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
                 GROUP BY #{group_by}").each do |dbc|
        next if dbc[group_by].to_i == 0 # anonimos
        points[dbc[group_by].to_i] ||= 0
        points[dbc[group_by].to_i] += dbc['count'].to_i * Faith::FPS_ACTIONS[attr_info]
      end
    end
    
    # competitions_matches
    CompetitionsMatch.find(:all, :conditions => "#{Competition::COMPLETED_ON_SQL} AND completed_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'").each do |cm|
      us = []
      us += cm.participant1.users if cm.participant1
      us += cm.participant2.users if cm.participant2
      us.each do |u|
        points[u.id] ||= 0
        points[u.id] += Faith::FPS_ACTIONS['competitions_match']
      end
    end
    
    points
  end
  
  
  def self.user_daily_faith(u, date_start, date_end)
    res = {}
    User.db_query("SELECT faith,
                        created_on
                   FROM stats.users_daily_stats
                  WHERE user_id = #{u.id}
                    AND created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
                 ORDER BY created_on").each do |dbr|
      res[dbr['created_on'][0..10]] = dbr['faith'].to_i            
    end
    curdate = date_start
    curstr = curdate.strftime('%Y-%m-%d')
    endd = date_end.strftime('%Y-%m-%d')
    
    while curstr <= endd
      res[curstr] ||= 0
      curdate = curdate.advance(:days => 1)
      curstr = curdate.strftime('%Y-%m-%d')
    end
    res
  end
  
  def self.reset_remaining_rating_slots
    # lo hacemos de uno en uno porque si no incurreimos en deadlocks
    User.db_query("SELECT id FROM users where lastseen_on >= now() - '15 days'::interval").each do |dbr|
      User.db_query("UPDATE users SET cache_remaining_rating_slots = NULL WHERE id = #{dbr['id']}")
    end
  end
  
  def self.faction_faith_points(faction)
    User.db_query("SELECT SUM(COALESCE(cache_faith_points, 0)) FROM users WHERE faction_id = #{faction.id}")[0]['sum'].to_i
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
end
