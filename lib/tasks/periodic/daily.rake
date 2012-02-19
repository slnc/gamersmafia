namespace :gm do
  desc "Daily operations"
  task :daily => :environment do
    require 'app/controllers/application_controller'

    begin
      Rake::Task['log:clear'].invoke
    rescue
    end

    Rake::Task['gm:alariko'].invoke
    clear_anonymous_users
    clear_faith_points_of_referers_and_resurrectors
    pay_faith_prices
    send_happy_birthday
    switch_inactive_users_to_zombies
    clear_file_caches
    send_reports_to_publisher_if_on_due_date
    new_accounts_cleanup
    check_ladder_matches
    update_portals_hits_stats
    provocar_golpes_de_estado
    forget_old_tracker_items
    forget_old_pageviews
    forget_old_autologin_keys
    forget_old_treated_visitors
    check_faction_leaders
    generate_daily_ads_stats
    kill_zombified_staff
    close_old_open_questions

    update_users_karma_stats
    update_users_daily_stats
    Popularity.update_rankings
    Karma.update_ranking
    Faith.update_ranking
    update_max_cache_valorations_weights_on_self_comments
    delete_empty_content_tags_terms
    delete_old_users_newsfeeds
  end

  def delete_old_users_newsfeeds
    UsersNewsfeed.old.delete_all
  end

  def delete_empty_content_tags_terms
    Term.contents_tags.find(:all, :conditions => 'contents_count = 0').each do |t|
      next if t.contents_terms.count > 0 || t.users_contents_tags.count > 0
      t.destroy
    end and nil
  end

  def update_max_cache_valorations_weights_on_self_comments
    User.db_query("update global_vars set max_cache_valorations_weights_on_self_comments = (select max(cache_valorations_weights_on_self_comments) from users where cache_valorations_weights_on_self_comments is not null);")
  end

  def forget_old_pageviews
    User.db_query("delete from stats.pageviews where created_on <= now() - '3 months'::interval")
  end

  def kill_zombified_staff
    # bigbosses, editors, moderators and sicarios
    limit = 3.months.ago
    now = Time.now
    mrcheater = User.find_by_login!('mrcheater')
    UsersRole.find(:all, :conditions => "role IN ('Don', 'ManoDerecha', 'Boss', 'Underboss', 'Editor', 'Moderator', 'Sicario')", :include => :user).each do |ur|
      if ur.user.lastseen_on < limit
        ur.destroy
        SlogEntry.create(:type_id => SlogEntry::TYPES[:info], :headline => "Quitando permiso de <strong>#{ur.role}</strong> a <strong>#{ur.user.login}</strong> por volverse zombie", :reviewer_user_id => mrcheater.id, :completed_on => now)
      end
    end
  end

  def close_old_open_questions
    mrman = User.find_by_login!('mrman')
    Question.published.find(:all, :conditions => 'answered_on IS NULL AND created_on <= now() - \'1 month\'::interval', :order => 'id').each do |q|
      c_text = Kernel.rand > 0.5 ? 'Esta pregunta lleva pendiente de respuesta demasiado tiempo y le está empezando a salir musgo verde así que me veo en la obligación de cerrarla.' : 'Esta pregunta lleva demasiado tiempo abierta y se encuentra en paupérrimas condiciones. Por consiguiente me siento con la obligación de cerrarla.'
      if q.unique_content.comments.count(:conditions => ['user_id <> ?', q.user_id]) > 0
        c_text << ' Si alguna de las respuestas es válida por favor avisad al staff.'
      end

      c = Comment.create(:user_id => mrman.id, :comment => c_text, :host => '127.0.0.1', :content_id => q.unique_content_id)

      q.set_no_best_answer(mrman)
    end
  end

  def generate_daily_ads_stats
    # sacamos todas las impresiones ads del día
    last_stats = User.db_query("SELECT created_on FROM stats.ads_daily ORDER BY created_on DESC LIMIT 1")
    max = 1.day.ago.beginning_of_day

    if last_stats.size > 0
      start = last_stats[0]['created_on'].to_time.advance(:days => 1)
    else
      start = 1.day.ago.beginning_of_day
    end

    cur = start
    while cur.strftime('%Y-%m-%d') <= max.strftime('%Y-%m-%d')
      tstart = cur
      tend = tstart.end_of_day
      Stats.consolidate_ads_daily_stats(tstart, tend)
      cur = cur.advance(:days => 1)
    end
    #puts "select count(*), ads_shown from stats.pageviews where created_on BETWEEN '#{tstart.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{tend.strftime('%Y-%m-%d %H:%M:%S')}' group by ads_shown order by ads_shown"
  end

  def check_faction_leaders
    # TODO TEMP, esto no debería ser necesario
    User.db_query("update users set cache_is_faction_leader = 't' where id in (select user_id FROM users_roles WHERE role IN ('Boss', 'Underboss'));")
  end

  def forget_old_autologin_keys
    AutologinKey.delete_all("lastused_on < now() - '1 month'::interval")
    User.db_query("select count(*), user_id from autologin_keys group by user_id HAVING count(*) > 3 order by count(*) desc").each do |dbr|
      uid = dbr['user_id']
      AutologinKey.delete_all("user_id = #{uid}
                         AND id NOT IN (select id
                                          FROM autologin_keys
                                         where user_id = #{uid}
                                      order by id desc
                                         limit 3)")
    end
  end

  def forget_old_tracker_items
    User.db_query("INSERT INTO archive.tracker_items (SELECT *
                                                        FROM public.tracker_items
                                                       WHERE lastseen_on < now() - '3 months'::interval)")
    User.db_query("DELETE FROM tracker_items
                         WHERE lastseen_on < now() - '3 months'::interval")
  end

  def forget_old_treated_visitors
    User.db_query("INSERT INTO archive.treated_visitors (SELECT *
                                                        FROM public.treated_visitors
                                                       WHERE ab_test_id IN (select id from ab_tests where completed_on is not null and dirty = 'f' and updated_on < now() - '2 weeks'::interval))")
    User.db_query("DELETE FROM treated_visitors
                         WHERE ab_test_id IN (select id from ab_tests where completed_on is not null and dirty = 'f' and updated_on < now() - '2 weeks'::interval)")
  end

  def forget_old_pageviews
    User.db_query("INSERT INTO archive.pageviews (SELECT *
                                                    FROM stats.pageviews
                                                   WHERE created_on < now() - '120 days'::interval)")
    User.db_query("DELETE FROM stats.pageviews
                         WHERE created_on < now() - '120 days'::interval")
  end

  def update_portals_hits_stats
    User.db_query("select count(*),
                          portal_id
                     from stats.pageviews
                    where portal_id > 0
                      AND created_on >= now() - '1 month'::interval
                 group by portal_id").each do |dbr|
      portal = Portal.find_by_id(dbr['portal_id'])
      if portal.nil?
        puts "daily.update_portals_hits_stats(). Warning, portal id #{dbr['portal_id']} (#{dbr['count']} pageviews) not found"
      else
        portal.cache_recent_hits_count = dbr['count'].to_i
        portal.save
      end
    end
    CacheObserver.expire_fragment("/common/gnav/#{Time.now.strftime('%Y-%m-%d')}")
  end



  def provocar_golpes_de_estado
    require "#{Rails.root}/app/controllers/application_controller" # necesario por llamada a ApplicationController
    mrcheater = User.find_by_login!('MrCheater')
    if [7, 8].include?(Time.now.month)
      days = 12
    else
      days = 6
    end

    Faction.find(:all, :conditions => "code IN (
select (select code from portals where id = stats.portals.portal_id)
  from stats.portals
 where portal_id in (select id
                       from portals
                      where code in (select code
                                       from games UNION
                                     select code from platforms))
   and created_on >= now() - '#{days+1} days'::interval
 group by portal_id
having portal_id in (select id
                       from portals
                      where code in (select code
                                       from factions
                                      where created_on < now() - '14 days'::interval
                                        and id IN #{Faction.factions_ids_with_bigbosses}))
             AND sum(karma) = 0)").each do |f|
      # avisamos de que mañana se provocará golpe de estado si no hacen nada
      [f.boss, f.underboss].each do |u|
        next if u.nil?
        m = Message.create(:user_id_from => mrcheater.id, :user_id_to => u.id, :title => 'Peligro: Golpe de estado inminente', :message => "Han pasado 6 días sin generarse ni un comentario o contenido en la facción #{f.name}. Si la situación no cambia hoy perderás el control de la facción.")
      end
    end

    Faction.find(:all, :conditions => "code IN (
select (select code from portals where id = stats.portals.portal_id)
  from stats.portals
 where portal_id in (select id
                       from portals
                      where code in (select code
                                       from games UNION
                                     select code from platforms))
   and created_on >= now() - '#{days+3} days'::interval
 group by portal_id
having portal_id in (select id
                       from portals
                      where code in (select code
                                       from factions
                                      where created_on < now() - '15 days'::interval
                                       and id IN #{Faction.factions_ids_with_bigbosses}))
             AND sum(karma) = 0)").each do |f|
      # mrCheater provoca golpe de estado publicando un tópic al respecto
      #puts "golpe de estado a #{f.name}"
      f.golpe_de_estado
    end
  end


  def check_ladder_matches
    # 1 week old and still unaccepted
    Ladder.find(:all, :conditions => ['state = ?', Competition::STARTED]).each do |l|
      l.matches(:unapproved, :conditions => 'accepted is false and updated_on < now() - \'1 week\'::interval and updated_on > now() - \'3 weeks\'::interval').each do |m|
        rt = m.participant2.the_real_thing
        if rt.class.name == 'User'
          recipients = [rt]
        else
          recipients = rt.admins
        end

        recipients.each do |u|
          Notification.reto_pendiente_1w(
              u, {:match => m, :participant => m.participant2}).deliver
        end
      end


      # 3 weeks old and still unaccepted, 2 warning
      l.matches(:unapproved, :conditions => 'accepted is false and updated_on < now() - \'3 weeks\'::interval and updated_on > now() - \'1 month\'::interval').each do |m|
        rt = m.participant2.the_real_thing
        if rt.class.name == 'User'
          recipients = [rt]
        else
          recipients = rt.admins
        end

        recipients.each do |u|
          # TODO(slnc): temporalmente deshabilitado
          # Notification.deliver_reto_pendiente_2w(u, {:match => m, :participant => m.participant2})
        end
      end


      # cancel older challenges
      l.matches(:unapproved, :conditions => 'accepted is false and updated_on < now() - \'1 month\'::interval').each do |m|
        rt = m.participant2.the_real_thing
        if rt.class.name == 'User'
          recipients = [rt]
        else
          recipients = rt.admins
        end

        recipients.each do |u|
          Notification.reto_cancelado_sin_respuesta(
              u, {:match => m, :participant => m.participant2}).deliver
        end
        m.destroy
      end

      # automatically accept unconfirmed results if older than a month
      l.matches(:result_pending, :conditions => 'updated_on < now() - \'1 month\'::interval').each do |m|
        if !(m.participant1_confirmed_result && m.participant2_confirmed_result) then # double forfeit
          m.complete_match(User.find_by_login!('MrMan'), {}, true)
        else # accept result
          rt = m.participant2.the_real_thing
          if rt.class.name == 'User'
            recipients = [rt]
          else
            recipients = rt.admins
          end

          recipients.each do |u|
            # TODO(slnc): deberíamos habilitar esto de nuevo?
            #Notification.reto_cancelado_sin_respuesta(u, {:match => m, :participant => m.participant2})
          end
          m.complete_match(User.find_by_login!('MrMan'), {}, true)
        end

      end
    end
  end

  def switch_inactive_users_to_zombies
    # pasamos usuarios que estaban activos o resucitados a zombies
    User.db_query("UPDATE users SET state = #{User::ST_ZOMBIE} WHERE state IN (#{User::ST_ACTIVE}, #{User::ST_RESURRECTED}) AND lastseen_on < now() - '3 months'::interval;")
  end

  def new_accounts_cleanup
    # 1st warning
    User.find(:all, :conditions => "state = #{User::ST_UNCONFIRMED} AND updated_at < now() - '3 days'::interval", :limit => 200).each do |u|
      Notification.unconfirmed_1w(u).deliver
      User.db_query("UPDATE users SET state = #{User::ST_UNCONFIRMED_1W}, updated_at = now() WHERE id = #{u.id}")
    end

    # 2nd warning
    User.find(:all, :conditions => "state = #{User::ST_UNCONFIRMED_1W} AND updated_at < now() - '3 days'::interval", :limit => 200).each do |u|
      Notification.unconfirmed_2w(u).deliver
      User.db_query("UPDATE users SET state = #{User::ST_UNCONFIRMED_2W}, updated_at = now() WHERE id = #{u.id}")
    end

    # delete older unconfirmed accounts
    User.find(:all, :conditions => "state = #{User::ST_UNCONFIRMED_2W} AND updated_at < now() - '3 days'::interval", :limit => 200).each do |u|
      User.db_query("UPDATE users SET state = #{User::ST_DELETED}, updated_at = now() WHERE id = #{u.id}")
    end
  end

  def send_reports_to_publisher_if_on_due_date
    # This scripts executes on the first day of the non paid period so we return the info ending yesterday midnight
    tend = Time.now.at_beginning_of_day.ago(1)
    tstart = tend.months_ago(1).beginning_of_day
    Advertiser.find(:all, :conditions => ['active=\'t\' AND due_on_day = ?', Time.now.day]).each do |advertiser|
      Notification.ad_report(
          advertiser, {:tstart => tstart, :tend => tend}).deliver
    end
  end

  def send_happy_birthday
    # enviamos un mensaje de felicitación
    nagato = User.find_by_login!('nagato')
    today = Date.today
    User.can_login.birthday_today.find(:all).each do |u|
      m = Message.new({ :sender => nagato,
        :recipient => u,
        :title => '¡Feliz cumpleaños!',
        :message => "¡En nombre de todo el staff de gamersmafia te deseo un feliz día de cumpleaños! :)\n\nNos vemos por la web." })
      m.save
    end
  end

  def clear_faith_points_of_referers_and_resurrectors
    parsed_referers = []
    User.can_login.find(:all, :conditions => "referer_user_id is not null and lastseen_on between (now() - '3 months 2 days'::interval) and (now() - '3 months'::interval)").each do |u|
      next if parsed_referers.include?(u.referer_user_id)
      r = User.find(u.referer_user_id)
      r.cache_faith_points = nil
      r.save
      r.faith_points
      parsed_referers<< u.referer_user_id
    end

    User.can_login.find(:all, :conditions => "resurrected_by_user_id is not null and lastseen_on between (now() - '3 months 2 days'::interval) and (now() - '3 months'::interval)").each do |u|
      next if parsed_referers.include?(u.referer_user_id)
      r = User.find(u.resurrected_by_user_id)
      r.cache_faith_points = nil
      r.save
      r.faith_points
      parsed_referers<< u.resurrected_by_user_id
    end
  end

  def pay_faith_prices
    # damos los premios por nivel de fe elevado
    User.can_login.find(:all, :conditions => "lastseen_on >= now() - '3 months'::interval and cache_faith_points > 0", :order => 'lastseen_on DESC').each do |u|
      faith_level = Faith.level(u)
      new_cash = Bank::convert(faith_level, 'faith_level')
      if new_cash > 0 then
        Bank.transfer(:bank, u, new_cash, "Nivel de fe (#{Faith::NAMES[faith_level]}) correspondiente a #{Time.new.ago(86400).strftime('%d %b %Y')}")
      end
    end
  end


  def clear_anonymous_users
    User.db_query('delete from anonymous_users where lastseen_on < now()  - \'30 minutes\'::interval')
  end

  def clear_file_caches
    #`find #{FRAGMENT_CACHE_PATH}/home -name daily_\\\* -type f -mmin +1440 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH} -maxdepth 3 -mindepth 1 -name \\\*online_state\\\* -type f -mmin +60 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/*/*/*/most_popular* -type f -mmin +1450 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/common/foros/_most_active_users/ -type f -mmin +1450 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/*/home/index -name apuestas* -type f -mmin +120 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/common/miembros/_top_bloggers/ -type f -mmin +1450 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/common/miembros/index/ -type f -mmin +1450 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/common/miembros/_rightside/birthdays_20* -type f -mmin +1450 -exec rm {} \\\;`
    `find /tmp -maxdepth 1 -name RackMultipart\\\* -mmin +60 -exec rm {} \\\;`
    `find /tmp -maxdepth 1 -name CGI\\\* -mmin +60 -exec rm {} \\\;`
  end

  def update_users_karma_stats
    max_day = 1.day.ago
    start_day = User.db_query("SELECT created_on
                                 FROM stats.users_karma_daily_by_portal
                             ORDER BY created_on DESC LIMIT 1")
    if start_day.size > 0
      start_day = start_day[0]['created_on'].to_time.advance(:days => 1)
      if start_day < max_day
        cur_day = start_day
      else
        cur_day = max_day
      end
    else # no hay records, cogemos el m:as viejo
      cur_day = User.db_query("SELECT created_on from contents order by created_on asc limit 1")[0]['created_on'].to_time
    end

    cur_day = 1.day.ago.beginning_of_day if Rails.env == 'test'

    while cur_day <= max_day
      # puts cur_day
      # iteramos a través de todos los users que han creado contenidos o comentarios hoy
      User.find(:all, :conditions => "id IN (select user_id
                                               from contents
                                              where state = #{Cms::PUBLISHED}
                                                AND date_trunc('day', created_on) = '#{cur_day.strftime('%Y-%m-%d')} 00:00:00' UNION
                                                select user_id
                                               from comments
                                              where deleted = 'f' AND date_trunc('day', created_on) = '#{cur_day.strftime('%Y-%m-%d')} 00:00:00')").each do |u|
        # TODO here
        Karma.karma_points_of_user_at_date(u, cur_day).each do |portal_id, points|
          # puts "#{u.login} #{portal_id} #{points}"
          User.db_query("INSERT INTO stats.users_karma_daily_by_portal(user_id, portal_id, karma, created_on) VALUES(#{u.id}, #{portal_id}, #{points}, '#{cur_day.strftime('%Y-%m-%d')}')")
        end
      end
      cur_day = cur_day.advance(:days => 1)
    end
    # TODO TESTS!!!!
  end

  def update_users_daily_stats
    # AFTER update_users_karma_stats
    max_day = 1.day.ago
    start_day = User.db_query("SELECT created_on
                                 FROM stats.users_daily_stats
                             ORDER BY created_on DESC LIMIT 1")
    if start_day.size > 0
      start_day = start_day[0]['created_on'].to_time.advance(:days => 1)
      if start_day < max_day
        cur_day = start_day
      else
        cur_day = max_day
      end
    else # no hay records, cogemos el m:as viejo
      cur_day = User.db_query("SELECT created_on from contents order by created_on asc limit 1")[0]['created_on'].to_time
    end

    cur_day = 1.day.ago.beginning_of_day if Rails.env == 'test'

    while cur_day <= max_day
      # puts cur_day
      # iteramos a través de todos los users que han creado contenidos o comentarios hoy
      pointz = {}

      User.find(:all, :conditions => "id IN (select user_id
                                               from contents
                                              where state = #{Cms::PUBLISHED}
                                                AND date_trunc('day', created_on) = '#{cur_day.strftime('%Y-%m-%d')} 00:00:00' UNION
                                                select user_id
                                               from comments
                                              where deleted = 'f' AND date_trunc('day', created_on) = '#{cur_day.strftime('%Y-%m-%d')} 00:00:00')").each do |u|
        # TODO here

        Karma.karma_points_of_user_at_date(u, cur_day).each do |portal_id, points|
          pointz[u.id] ||= {:karma => 0, :faith => 0, :popularity => 0}
          pointz[u.id][:karma] += points
          # puts "#{u.login} #{portal_id} #{points}"
          # User.db_query("INSERT INTO stats.users_karma_daily_by_portal(user_id, portal_id, karma, created_on) VALUES(#{u.id}, #{portal_id}, #{points}, '#{cur_day.strftime('%Y-%m-%d')}')")
        end
      end

      # ahora calculamos stats de fe
      faithres = Faith.faith_points_of_users_at_date_range(cur_day.beginning_of_day, cur_day.end_of_day)
      faithres.keys.each do |uid|
        pointz[uid] ||= {:karma => 0, :faith => 0, :popularity => 0}
        pointz[uid][:faith] += faithres[uid]
      end

      # popularidad
      User.hot('all', cur_day.beginning_of_day, cur_day.end_of_day).each do |hinfo|
        pointz[hinfo[0].id] ||= {:karma => 0, :faith => 0, :popularity => 0}
        pointz[hinfo[0].id][:popularity] = hinfo[1]
      end

      pointz.keys.each do |uid|
        v = pointz[uid]
        User.db_query("INSERT INTO stats.users_daily_stats(user_id, karma, faith, popularity, created_on) VALUES(#{uid}, #{v[:karma]}, #{v[:faith]}, #{v[:popularity]}, '#{cur_day.strftime('%Y-%m-%d')}')")
      end


      # clans
      # popularidad
      Clan.hot('all', cur_day.beginning_of_day, cur_day.end_of_day).each do |hinfo|
        pointz[hinfo[0].id] ||= {:popularity => 0}
        pointz[hinfo[0].id][:popularity] = hinfo[1]
      end

      pointz.keys.each do |uid|
        v = pointz[uid]
        next unless Clan.find_by_id(uid)
        User.db_query("INSERT INTO stats.clans_daily_stats(clan_id, popularity, created_on) VALUES(#{uid}, #{v[:popularity]}, '#{cur_day.strftime('%Y-%m-%d')}')")
      end

      cur_day = cur_day.advance(:days => 1)
    end
    # TODO TESTS!!!!
  end
end
