module Emblems
  # el índice implica la importancia
  EMBLEMS = {
    # ordenados
    :webmaster => {:title => 'Webmaster', :index => 0},
    :capo => {:title => 'Capo', :index => 1},
    :boss => {:title => 'Boss', :index => 2},
    :underboss => {:title => 'Underboss', :index => 3},
    :editor => {:title => 'Editor', :index => 4},
    :moderator => {:title => 'Moderador', :index => 5},
    :don => {:title => 'Don', :index => 6},
    :mano_derecha => {:title => 'Mano derecha', :index => 7},
    :sicario => {:title => 'Sicario', :index => 8},
    :hq => {:title => 'Miembro del HQ', :index => 9},
    :best_overall => {:title => 'Mafioso supremo', :index => 10},
    :karma_fury => {:title => 'Furia kármica', :index => 11},
    :faith_avalanche => {:title => 'Elegido por los dioses', :index => 12},
    :most_knowledgeable => {:title => 'Avatar de la sabiduría', :index => 13},
    :living_legend => {:title => 'Leyenda viva', :index => 14},
    :funniest => {:title => 'El más divertido', :index => 15},
    :profoundest => {:title => 'El más profundo', :index => 16},
    :most_informational => {:title => 'El más informativo', :index => 17},
    :most_interesting => {:title => 'El más interesante', :index => 18},
    :wealthiest => {:title => 'El más rico', :index => 19},
    :okupa => {:title => 'Omnipresente', :index => 20},
    :bets_master => {:title => 'Maestro de las apuestas', :index => 21},
    :best_blogger => {:title => 'Blogger A-List', :index => 23},
    :oldest_faction_member => {:title => 'Pionero de su facción', :index => 24},
    :baby => {:title => 'Recién registrado', :index => 25},

    # DEPRECATED: mantenemos los siguientes emblemas por razones históricas y
    # para que las personas que los ganaron los conserven pero ya no se otorgan
    # más.
    :talker => {:title => 'Hablador', :index => 22},
  }

  EMBLEMS_TO_REPORT = %w(best_blogger
                         best_overall
                         bets_master
                         faith_avalanche
                         funniest
                         karma_fury
                         living_legend
                         most_informational
                         most_interesting
                         most_knowledgeable
                         okupa
                         profoundest
                         wealthiest
                         )

  EMBLEMS_BY_INDEX = begin
    res = {}
    EMBLEMS.each do |k,v|
      res[v[:index]] = k
    end
    res
  end

  def self.give_emblems
    # si ha pasado una semana desde los últimos emblemas genera los emblemas actuales
    # TODO chequeos
    last_ue = UsersEmblem.find(:first, :order => 'created_on DESC', :limit => 1)
    if last_ue
      if last_ue.created_on.to_time.to_i > 5.days.ago.to_i
        puts "Error: el último emblema se dio el #{last_ue.created_on}"
        return
      end
    end

    # hq
    User.find(:all, :conditions => 'is_hq = \'t\'').each do |u|
      #puts "dando hq a #{u.login}"
      u.users_emblems.create(:emblem => 'hq')
    end

    User.find(:all, :conditions => 'is_superadmin = \'t\'').each do |u|
      u.users_emblems.create(:emblem => 'webmaster')
    end

    User.can_login.find(:all, :conditions => "created_on >= now() - 
                                             '1 week'::interval").each do |u|
      u.users_emblems.create(:emblem => 'baby')
    end

    bosses = [0]
    User.can_login.find(:all, :conditions => "id IN (SELECT user_id 
                                                       FROM users_roles 
                                                      WHERE role = 'Boss')").each do |u|
      u.users_emblems.create(:emblem => 'boss')
      bosses<< u.id
    end

    underbosses = [0]
    User.can_login.find(:all, :conditions => "id IN (SELECT user_id 
                                             FROM users_roles
                                            WHERE role = 'Underboss')").each do |u|
      u.users_emblems.create(:emblem => 'underboss')
      underbosses<< u.id
    end

    dons = [0]
    User.can_login.find(:all, :conditions => "id IN (SELECT user_id FROM users_roles WHERE role = '#{BazarDistrict::ROLE_DON}') AND id NOT IN (#{bosses.join(',')}) AND id NOT IN (#{underbosses.join(',')})").each do |u|
      u.users_emblems.create(:emblem => 'don')
      dons<< u.id
    end

    mano_derechas = [0]
    User.can_login.find(:all, :conditions => "id IN (SELECT user_id FROM users_roles WHERE role = '#{BazarDistrict::ROLE_MANO_DERECHA}') AND id NOT IN (#{bosses.join(',')}) AND id NOT IN (#{underbosses.join(',')})").each do |u|
      u.users_emblems.create(:emblem => 'mano_derecha')
      mano_derechas<< u.id
    end

    User.find_with_admin_permissions(:capo).each do |u|
      u.users_emblems.create(:emblem => 'capo')
    end

    User.can_login.find(:all, :conditions => "id IN (SELECT user_id FROM users_roles WHERE role = 'Sicario') AND id NOT IN (#{bosses.join(',')}) AND id NOT IN (#{underbosses.join(',')}) AND id NOT IN (#{dons.join(',')})  AND id NOT IN (#{mano_derechas.join(',')})").each do |u|
      u.users_emblems.create(:emblem => 'sicario')
    end

    User.can_login.find(:all, :conditions => "id IN (SELECT user_id FROM users_roles WHERE role = 'Editor') AND id NOT IN (#{bosses.join(',')}) AND id NOT IN (#{underbosses.join(',')}) AND id NOT IN (#{dons.join(',')})  AND id NOT IN (#{mano_derechas.join(',')})").each do |u|
      u.users_emblems.create(:emblem => 'editor')
    end

    User.can_login.find(:all, :conditions => "id IN (SELECT user_id FROM users_roles WHERE role = 'Moderator') AND id NOT IN (#{bosses.join(',')}) AND id NOT IN (#{underbosses.join(',')}) AND id NOT IN (#{dons.join(',')})  AND id NOT IN (#{mano_derechas.join(',')})").each do |u|
      u.users_emblems.create(:emblem => 'moderator')
    end

    points = Karma::karma_points_of_users_at_date_range(Time.now, 1.week.ago)
    if points.size > 0
      maxk = 0
      max_uid = nil
      points.each do |u,k|
        if maxk.nil? || k > maxk
          maxk = k
          max_uid = u
        end
      end

      User.find(max_uid.to_i).users_emblems.create(:emblem => 'karma_fury', :details => "<strong>#{maxk}</strong> puntos de karma")
  end

  points = Faith::faith_points_of_users_at_date_range(Time.now, 1.week.ago)
  if points.size > 0
    maxk = 0
    max_uid = nil
    points.each do |u,k|
      if maxk.nil? || k > maxk
        maxk = k
        max_uid = u
      end
    end


    User.find(max_uid.to_i).users_emblems.create(:emblem => 'faith_avalanche', :details => "<strong>#{maxk}</strong> puntos de fe") unless max_uid.nil?
  end

  # oldest faction_members
  Faction.find(:all, :conditions => 'members_count > 0').each do |f|
    u = f.oldest_active_member
    next unless u
    u.users_emblems.create(:emblem => 'oldest_faction_member', :details => "miembro desde <strong>#{u.faction_last_changed_on.strftime('%d del %b de %Y')}</strong>")
  end

  # living_legend
  mp = User.most_friends(10)
  if mp.size > 0
    maxf = nil
    mp.each do |h|
      maxf = h[:friends] if maxf.nil? || h[:friends] > maxf
      h[:user].users_emblems.create(:emblem => 'living_legend', :details => "<strong>#{maxf}</strong> amigos") if h[:friends] == maxf
    end
  end

  # wealthiest living
  maxc = nil
  User.find(:all, :conditions => "state <> #{User::ST_UNCONFIRMED} and cash > 0 and is_bot is false AND lastseen_on > now() - '3 months'::interval", :order => 'cash DESC', :limit => 10).each do |u|
    maxc = u.cash if maxc.nil? || u.cash > maxc
    u.users_emblems.create(:emblem => 'wealthiest', :details => "Muchos GMFs") if u.cash == maxc
  end

  # top commenters de cada tipo
  r_emblems = {'Divertido' => 'funniest', 'Interesante' => 'most_interesting', 'Profundo' => 'profoundest', 'Informativo' => 'most_informational'}
  CommentsValorationsType.find_positive.each do |cvt|
    # wealthiest living
    max = nil
    max_u = nil
    h = Comments.top_commenter_of_type_in_time_period(cvt, Time.now, 1.week.ago, 1)
    if h.size > 0
      sum, u = h[0][0], h[0][1]
      u.users_emblems.create(:emblem => r_emblems[cvt.name], :details => "<strong>#{sum}</strong> puntos")
    end
  end

  # bets_master
  mp = Bet.top_earners('7 days')
  if mp.size > 0
    maxc = nil
    mp.each do |h|
      u, sum = h[0], h[1]
      sum = -sum.to_f
      maxc = sum if maxc.nil? || sum > maxc
      u.users_emblems.create(:emblem => 'bets_master', :details => "<strong>#{maxc}</strong> GMFs ganados") if sum == maxc
    end
  end

  # best blogger
  mp = Blogs.top_bloggers_in_date_range(Time.now, 1.week.ago)
  if mp.size > 0
    maxc = nil
    mp.each do |h|
      u, sum = h[0], h[1]
      sum = sum.to_i
      maxc = sum if maxc.nil? || sum > maxc
      u.users_emblems.create(:emblem => 'best_blogger', :details => "<strong>#{maxc}</strong> visitas") if sum == maxc
    end
  end

  # most knowledgeable
  mp = Question.top_sages_in_date_range(Time.now, 1.week.ago)
  if mp.size > 0
    maxc = nil
    mp.each do |h|
      u, sum = h[0], h[1]
      sum = sum.to_i
      maxc = sum if maxc.nil? || sum > maxc
      u.users_emblems.create(:emblem => 'most_knowledgeable', :details => "<strong>#{maxc}</strong> mejores respuestas") if sum == maxc
    end
  end


  # ACTUALIZAMOS emblemas
  # p User.db_query("select user_id FROM users_emblems WHERE created_on = '#{last_ue.created_on.to_time.strftime('%Y-%m-%d')}'") if last_ue
  User.db_query("UPDATE users SET emblems_mask = '' WHERE id IN (select user_id FROM users_emblems WHERE created_on = '#{last_ue.created_on.to_time.strftime('%Y-%m-%d')}')") if last_ue
  update_current_users_emblems
end

def self.update_current_users_emblems(d=Time.now)
  cur_date = d.strftime('%Y-%m-%d')
  User.find(:all, :conditions => "id IN (select user_id FROM users_emblems WHERE created_on = '#{cur_date}')").each do |u|
    m = ''
    u.users_emblems.find(:all, :conditions => "created_on = '#{cur_date}'").each do |e|
      m = m.ljust(e.index, '0') if m.size < e.index
      m[(e.index)..(e.index)] = '1'
    end
    u.emblems_mask = m
    u.save
  end
end

def self.get_latest_emblems
  ue = UsersEmblem.find(:first, :order => 'users_emblems.created_on DESC', :include => :user)
  return [] if ue.nil?
  str_cls = EMBLEMS_TO_REPORT.collect { |er| "'#{er}'" }.join(',')
  UsersEmblem.find(:all, :conditions => "emblem IN (#{str_cls}) AND created_on = '#{ue.created_on}'", :order => 'lower(emblem)')
end
end
