module Karma
  POINTS_FIRST_LEVEL = 500
  INCREMENT_PER_LEVEL = 0.05
  KPS_CREATE = {'News'=> 60,  
                'Image'=> 20, 
                'Download'=> 30,
                'Demo'=> 40,
                'Topic'=> 20, 
                'Poll'=> 40, 
                'Bet'=> 40, 
                'Event'=> 30, 
                'Coverage'=> 30, 
                'Tutorial'=> 400,
                'Interview'=> 500,
                'Column'=> 300,
                'Review'=> 200,
                'Funthing'=> 20,
                'Blogentry'=> 20,
                'Question'=> 5,
                'Comment'=> 5,
  }
  
  KPS_SAVE = {'News'=> 10,  
              'Image'=> 10, 
              'Download'=> 10,
              'Demo'=> 10,
              'Poll'=> 10, 
              'Bet'=> 10, 
              'Event'=> 10, 
              'Coverage'=> 10,
              'Tutorial'=> 70, 
              'Interview'=> 70, 
              'Column'=> 70, 
              'Review'=> 40,
              'Question'=> 5,
              'Funthing'=> 10}
  
  def Karma.kp_for_level level
   (POINTS_FIRST_LEVEL * level) + (POINTS_FIRST_LEVEL * (level - 1)) * (INCREMENT_PER_LEVEL * level)
  end
  
  def Karma.pc_done_for_next_level(kp)
    cur_level = Karma.level(kp)
    kp_cur_lvl  = Karma.kp_for_level cur_level
    kp_next_lvl = Karma.kp_for_level(cur_level + 1)
    
    diff_100 = kp_next_lvl - kp_cur_lvl
    diff_done = kp - kp_cur_lvl
    
    return (100 * diff_done / diff_100).to_i
  end
  
  def Karma.level(kp)
    kp = kp.karma_points unless kp.is_a?(Fixnum)
    
    lvl = 0
    kp_for_lvl = 0
    
    if kp >= POINTS_FIRST_LEVEL
      
      while (kp > kp_for_lvl)
        lvl += 1
        kp_for_lvl = Karma.kp_for_level(lvl + 1)
      end
    end
    
    return lvl
  end
  
  def self.max_user_points
    User.db_query("SELECT max(cache_karma_points) FROM users")[0]['max'].to_i
  end
  
  def self.user_daily_karma(u, date_start, date_end)
    res = {}
    User.db_query("SELECT karma,
                        created_on
                   FROM stats.users_daily_stats
                  WHERE user_id = #{u.id}
                    AND created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
                 ORDER BY created_on").each do |dbr|
      res[dbr['created_on'][0..10]] = dbr['karma'].to_i            
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
  
  def self.karma_points_of_users_at_date_range(date_start, date_end)
    date_start, date_end = date_end, date_start if date_start > date_end
    points = {}
    User.db_query("SELECT count(*), 
                          user_id
                     FROM comments 
                    WHERE deleted = 'f'
                      AND (select is_bot FROM users WHERE id = user_id) = 'f' 
                      AND created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
                 GROUP BY user_id").each do |dbc|
      points[dbc['user_id']] = dbc['count'].to_i * Karma::KPS_CREATE['Comment']
    end
    
    # ahora contenidos
    User.db_query("SELECT count(*), 
                          user_id,
                          content_type_id
                     FROM contents 
                    WHERE state = #{Cms::PUBLISHED}
                      AND (select is_bot FROM users WHERE id = user_id) = 'f' 
                      AND created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}' 
                 GROUP BY user_id, content_type_id").each do |dbc|
      points[dbc['user_id']] ||= 0
      points[dbc['user_id']] += dbc['count'].to_i * Karma::KPS_CREATE[ContentType.find(dbc['content_type_id'].to_i).name]
    end
    points
  end
  
  def self.karma_points_of_user_at_date(user, date)
    # devuelve un array
    # [-1][50] 50 puntos en el portal con id -1
    points = {}
    User.db_query("SELECT count(*), 
                          portal_id 
                     FROM comments 
                    WHERE user_id = #{user.id}
                      AND deleted = 'f' 
                      AND date_trunc('day', created_on) = '#{date.strftime('%Y-%m-%d')} 00:00:00' 
                 GROUP BY portal_id").each do |dbc|
      points[dbc['portal_id']] = dbc['count'].to_i * Karma::KPS_CREATE['Comment']
    end
    
    # ahora contenidos
    User.db_query("SELECT count(*), 
                          portal_id,
                          content_type_id
                     FROM contents 
                    WHERE user_id = #{user.id}
                      AND state = #{Cms::PUBLISHED} 
                      AND date_trunc('day', created_on) = '#{date.strftime('%Y-%m-%d')} 00:00:00' 
                 GROUP BY portal_id, content_type_id").each do |dbc|
      points[dbc['portal_id']] ||= 0
      points[dbc['portal_id']] += dbc['count'].to_i * Karma::KPS_CREATE[ContentType.find(dbc['content_type_id'].to_i).name]
    end
    
    # TODO contenidos approved_by_user_id no se contabilizan
    #for c in Cms::contents_classes_publishable
    # author of
    #      points += c.count(:conditions => "user_id = #{thing.id} and state = #{Cms::PUBLISHED}") * Karma::KPS_CREATE[c.name]
    #points += c.count(:conditions => "approved_by_user_id = #{thing.id} and state = #{Cms::PUBLISHED}") * Karma::KPS_SAVE[c.name] # legacy
    #end
    
    points  
  end
  
  def self.calculate_karma_points(thing)
    if thing.kind_of?(User)
      points = 0
      
      points += thing.comments.count(:conditions => 'comments.deleted = \'f\'') * Karma::KPS_CREATE['Comment']
      points += thing.blogentries.count(:conditions => "state = #{Cms::PUBLISHED}") * Karma::KPS_CREATE['Blogentry']
      points += thing.topics.count(:conditions => "state = #{Cms::PUBLISHED}") * Karma::KPS_CREATE['Topic']
      
      for c in Cms::contents_classes_publishable
        # author of
        points += c.count(:conditions => "user_id = #{thing.id} and state = #{Cms::PUBLISHED}") * Karma::KPS_CREATE[c.name]
        points += c.count(:conditions => "approved_by_user_id = #{thing.id} and state = #{Cms::PUBLISHED}") * Karma::KPS_SAVE[c.name] # legacy
      end
      
      points
    elsif thing.class.kind_of?(ActsAsContent::AddActsAsContent)
      if thing.is_public?
        Karma::KPS_CREATE[thing.class.name] + Karma::KPS_SAVE[thing.class.name] + thing.cache_comments_count * Karma::KPS_CREATE['Comment']
      else 
        0
      end
    end
  end
  
  def self.give(user, points)
    raise TypeError unless (user.kind_of?(User) and points.kind_of?(Fixnum))
    raise ValueError unless points > 0
    
    user.karma_points # forzamos el cálculo desde 0, esto sí que puede incurrir en race condition
    user.cache_karma_points = User.db_query("UPDATE users SET cache_karma_points = cache_karma_points + #{points} WHERE id = #{user.id}; SELECT cache_karma_points FROM users WHERE id = #{user.id}")[0]['cache_karma_points']
  end
  
  def self.take(user, points)
    raise TypeError unless (user.kind_of?(User) and points.kind_of?(Fixnum))
    raise ValueError unless points > 0
    user.karma_points # forzamos el cálculo desde 0, esto sí que puede incurrir en race condition
    user.cache_karma_points = User.db_query("UPDATE users SET cache_karma_points = cache_karma_points - #{points} WHERE id = #{user.id}; SELECT cache_karma_points FROM users WHERE id = #{user.id}")[0]['cache_karma_points']
  end
  
  def self.ranking_user(u)
    # contamos incluso los que tienen 0
    ucount = User.db_query("SELECT count(*) FROM users WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')})")[0]['count'].to_i
    pos = u.ranking_karma_pos ? u.ranking_karma_pos : ucount 
    {:pos => pos, :total => ucount }
  end
  
  def self.update_ranking
    lista = {} 
    User.db_query("SELECT id, cache_karma_points FROM users WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')})").each do |dbr|
      lista[dbr['cache_karma_points'].to_i] ||= []
      lista[dbr['cache_karma_points'].to_i] << dbr['id'].to_i
    end
    
    pos = 1
    lista.keys.sort.reverse.each do |k|
      # en caso de empate los ids menores (mas antiguos) tienen preferencia
      lista[k].sort.each do |uid|
        User.db_query("UPDATE users SET ranking_karma_pos = #{pos} WHERE id = #{uid}")
        pos += 1
      end
    end
  end
end
