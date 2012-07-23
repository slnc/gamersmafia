namespace :gm do
  # TODO tests!!
  desc "Midnight operations"
  task :midnight => :environment do
    #dst_file = "c:\\tmp.png"
    #days = 31
    #s = 1.year.ago
    #e = s.advance(:days => 31)
    #dbi = Stats::Metrics::mdata('NewUsers', s, e)
    #`python script/spark.py metric #{dbi.collect {|dbr| dbr['count'] }.concat([0] * (days - dbi.size)).reverse.join(',')} "#{dst_file}"`
    #return

    Faith.delay.reset_remaining_rating_slots
    Faction.delay.update_factions_cohesion
    Bet.generate_top_bets_winners_minicolumns
    update_factions_stats # Order is important
    update_general_stats
    generate_minicolumns_factions_activity
  end

  def generate_minicolumns_factions_activity
    days = 23
    Faction.find(:all).each do |f|
      dbi = User.db_query("select karma from stats.portals where portal_id = (select id from portals where code = '#{f.code}') order by created_on desc limit #{days}")
      dst_file = "#{Rails.root}/public/storage/minicolumns/factions_activity/#{f.id}.png"

      FileUtils.mkdir_p(File.dirname(dst_file)) unless File.exists?(File.dirname(dst_file))
      `/usr/bin/python script/spark.py faction_activity #{dbi.collect {|dbr| dbr['karma'] }.concat([0] * (days - dbi.size)).reverse.join(',')} "#{dst_file}"`
    end
  end

  # Actualiza las estadísticas de karma generado por cada facción y por la web general
  # TODO no calcula karma generado por clanes
  def update_factions_stats
    dbmaxstats = User.db_query("SELECT MAX(created_on) FROM stats.portals")[0]
    if dbmaxstats['max'].to_i == 0 # no stats
      min_time  = User.db_query("SELECT MIN(created_on) FROM contents WHERE state = #{Cms::PUBLISHED}")[0]['min'].to_time
      min_time2 = User.db_query("SELECT MIN(created_on) FROM comments")[0]['min'].to_time
      min_time = min_time2 if min_time2 < min_time
    else
      min_time = dbmaxstats['max'].to_time
    end
    min_time = min_time.yesterday.beginning_of_day

    min_time = 1.day.ago.beginning_of_day if Rails.env == 'test'

    today = Time.now.beginning_of_day

    while min_time < today
      min_time_strted = min_time.strftime('%Y-%m-%d %H:%M:%S')

      portals_stats = {}
      games_r_portals = {}
      platforms_r_portals = {}
      bazar_districts_r_portals = {}
      clans_r_portals = {}
      general = 0

      # Comments
      # TODO esto cuenta comentarios de contenidos borrados
      Comment.find(:all, :conditions => "deleted = 'f' AND comments.created_on BETWEEN date_trunc('day', to_timestamp('#{min_time_strted}', 'YYYY-MM-DD HH24:MI:SS'))  AND date_trunc('day', to_timestamp('#{min_time_strted}', 'YYYY-MM-DD HH24:MI:SS')) + '1 day'::interval - '1 second'::interval", :include => [ :content]).each do |comment|
        if comment.content.game # Contenido de facción
          # Warning: un juego puede aparecer en más de un portal
          portal = Portal.find(:first, :conditions => ['code = ?', comment.content.game.code])
          if portal.nil?
            portal = Portal.find(:first, :conditions => ['name = ?', comment.content.game.name])
          end
          if portal
            games_r_portals[comment.content.game_id] ||= portal.id
            portals_stats[games_r_portals[comment.content.game_id]] ||= 0
            portals_stats[games_r_portals[comment.content.game_id]] += Karma::KPS_CREATE['Comment']
          else
            Rails.logger.warn("game #{comment.content.game.name} has no portal")
          end
        elsif comment.content.platform # Contenido de facción
          platforms_r_portals[comment.content.platform_id] ||= Portal.find(:first, :conditions => ['code = ?', comment.content.platform.code]).id
          portals_stats[platforms_r_portals[comment.content.platform_id]] ||= 0
          portals_stats[platforms_r_portals[comment.content.platform_id]] += Karma::KPS_CREATE['Comment']
        elsif comment.content.bazar_district # Contenido de distrito
          bazar_districts_r_portals[comment.content.bazar_district_id] ||= Portal.find(:first, :conditions => ['code = ?', comment.content.bazar_district.code]).id
          portals_stats[bazar_districts_r_portals[comment.content.bazar_district_id]] ||= 0
          portals_stats[bazar_districts_r_portals[comment.content.bazar_district_id]] += Karma::KPS_CREATE['Comment']
          #p portals_stats
        elsif comment.content.clan # Contenido de clan
          portal = Portal.find(:first, :conditions => ['clan_id = ?', comment.content.clan_id])
          if portal then
            clans_r_portals[comment.content.clan_id] ||= Portal.find(:first, :conditions => ['clan_id = ?', comment.content.clan_id]).id
            portals_stats[clans_r_portals[comment.content.clan_id]] ||= 0
            portals_stats[clans_r_portals[comment.content.clan_id]] += Karma::KPS_CREATE['Comment']
          else
            Rails.logger.warn(
              "clan_id: #{comment.content.clan_id} has no portal")
          end
        else
          general += Karma::KPS_CREATE['Comment']
        end
      end

      # Contents
      Content.find(:all, :conditions => "state = #{Cms::PUBLISHED} AND created_on BETWEEN date_trunc('day', to_timestamp('#{min_time_strted}', 'YYYY-MM-DD HH24:MI:SS'))  AND date_trunc('day', to_timestamp('#{min_time_strted}', 'YYYY-MM-DD HH24:MI:SS')) + '1 day'::interval - '1 second'::interval", :include => [:content_type]).each do |content|
        if content.game # Contenido de facción
          # Warning: un juego puede aparecer en más de un portal
          portal = Portal.find(:first, :conditions => ['code = ?', content.game.code])
          if portal.nil?
            portal = Portal.find(:first, :conditions => ['name = ?', content.game.name])
          end
          if portal
            games_r_portals[content.game_id] ||= portal.id
            portals_stats[games_r_portals[content.game_id]] ||= 0
            portals_stats[games_r_portals[content.game_id]] += Karma.contents_karma(content, false)
          else
            Rails.logger.warn(
              "game #{content.game_id ? content.game.name : content.name} has" +
              " no portal")
          end
        elsif content.platform # Contenido de facción
          platforms_r_portals[content.platform_id] ||= Portal.find(:first, :conditions => ['code = ?', content.platform.code]).id
          portals_stats[platforms_r_portals[content.platform_id]] ||= 0
          portals_stats[platforms_r_portals[content.platform_id]] += Karma.contents_karma(content, false)
        elsif content.bazar_district # Contenido de facción
          bazar_districts_r_portals[content.bazar_district_id] ||= Portal.find(:first, :conditions => ['code = ?', content.bazar_district.code]).id
          portals_stats[bazar_districts_r_portals[content.bazar_district_id]] ||= 0
          portals_stats[bazar_districts_r_portals[content.bazar_district_id]] += Karma.contents_karma(content, false)
        elsif content.clan # Contenido de clan
          portal = Portal.find(:first, :conditions => ['clan_id = ?', content.clan_id])
          if portal
            clans_r_portals[content.clan_id] ||= portal.id
            portals_stats[clans_r_portals[content.clan_id]] ||= 0
            portals_stats[clans_r_portals[content.clan_id]] += Karma.contents_karma(content, false)
          else
            Rails.logger.warn("clan_id: #{content.clan_id} has no portal")
          end
        else
          general += Karma.contents_karma(content, false)
        end
      end

      begin
        User.db_query("INSERT INTO stats.portals(created_on, portal_id, karma) VALUES('#{min_time.strftime('%Y-%m-%d')}', NULL, #{general})")
      rescue Exception
        User.db_query("UPDATE stats.portals SET karma = #{general} WHERE created_on = '#{min_time.strftime('%Y-%m-%d')}' AND portal_id IS NULL")
      end

      q = "insert into stats.portals(portal_id, karma, created_on, pageviews, visits, unique_visitors, unique_visitors_reg) select id, 0, '#{min_time.strftime('%Y-%m-%d')}',0 ,0, 0, 0 from portals where id not in (select portal_id from stats.portals where portal_id is not null AND created_on = '#{min_time.strftime('%Y-%m-%d')}')"
      User.db_query(q)
      # Ponemos a 0 las estadísticas del resto de portales
      # TODO cuando el campo created_on de portals represente fielmente el nacimiento de un portal esto se puede optimizar

      Portal.find(:all).each do |portal|
        portal_id = portal.id
        karma = portals_stats[portal_id] ? portals_stats[portal_id] : 0
        dbrstats_visits = User.db_query("SELECT count(*) as pageviews,
                                            count(distinct(session_id)) as visits,
                                            count(distinct(visitor_id)) as unique_visitors,
                                            count(distinct(user_id)) as unique_visitors_reg
                                       FROM stats.pageviews
                                      WHERE created_on
                                    BETWEEN date_trunc('day', to_timestamp('#{min_time_strted}', 'YYYY-MM-DD HH24:MI:SS'))
                                        AND date_trunc('day', to_timestamp('#{min_time_strted}', 'YYYY-MM-DD HH24:MI:SS')) + '1 day'::interval - '1 second'::interval
                                        AND portal_id = #{portal_id}")[0]
        pageviews = dbrstats_visits['pageviews']
        visits = dbrstats_visits['visits']
        unique_visitors = dbrstats_visits['unique_visitors']
        unique_visitors_reg = dbrstats_visits['unique_visitors_reg']

        #  begin
        #    User.db_query("INSERT INTO stats.portals(created_on, portal_id, karma, pageviews, visits, unique_visitors) VALUES('#{min_time.strftime('%Y-%m-%d')}', #{portal_id}, #{karma}, #{pageviews}, #{visits}, #{unique_visitors}, #{unique_visitors_reg})")
        #  rescue Exception
        User.db_query("UPDATE stats.portals SET karma = #{karma}, pageviews = #{pageviews}, visits = #{visits}, unique_visitors = #{unique_visitors}, unique_visitors_reg = #{unique_visitors_reg} WHERE created_on = '#{min_time.strftime('%Y-%m-%d')}' AND portal_id = #{portal_id}")
        #  end
      end
      min_time = min_time.advance(:days => 1)
    end
  end

  def update_general_stats
    # buscamos fecha más antigua de comentario
    # buscamos fecha más antigua en stats globales que tenga info de comentarios creados
    # actualizamos desde dicha fecha hasta ayer
    yesterday = 1.day.ago.beginning_of_day
    tonight = yesterday.advance(:days => 1)
    first_comment = User.db_query('SELECT min(created_on) FROM comments')[0]['min'].to_time
    first_stat = User.db_query("SELECT max(created_on) FROM stats.general WHERE new_comments is not null")[0]['max']
    first_stat = (first_stat and first_stat != '') ? first_stat.to_time : first_comment
    first_stat.advance(:days => 1).beginning_of_day # nos ponemos en el primer día que tenemos que calcular
    first_stat = 1.day.ago.beginning_of_day if Rails.env == 'test'

    while first_stat < tonight
      cur_str = first_stat.strftime('%Y-%m-%d')
      next_stat = first_stat.advance(:days => 1)
      created_clans = Clan.count(:conditions => "date_trunc('day', created_on) = date_trunc('day', '#{first_stat.strftime('%Y-%m-%d 00:00:00')}'::timestamp)")
      new_closed_topics = Topic.count(:conditions => "state = #{Cms::PUBLISHED} AND closed = 't' AND date_trunc('day', updated_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}'")
      new_clans_portals = ClansPortal.count(:conditions => "clan_id IS NOT NULL AND date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}'")
      dbrender = User.db_query("SELECT avg(time), stddev(time), avg(db_queries) as avg_dbq, stddev(db_queries) as stddev_dbq FROM stats.pageloadtime WHERE date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}'")[0]
      sql_created_on = "date_trunc('day', created_on) = date_trunc('day', '#{first_stat.strftime('%Y-%m-%d 00:00:00')}'::timestamp)"
      new_factions = Faction.count(:conditions => sql_created_on)
      sent_emails = SentEmail.count(:conditions => sql_created_on)
      downloaded_downloads_count = DownloadedDownload.count(:conditions => sql_created_on)
      avg_page_render_time = dbrender['avg'].to_f
      stddev_page_render_time = dbrender['stddev'].to_f
      avg_db_queries_per_request = dbrender['avg_dbq'].to_f
      stddev_db_queries_per_request = dbrender['stddev_dbq'].to_f
      karma_diff = Gmstats.karma_in_time_period(first_stat, next_stat)
      faith_diff = Gmstats.faith_in_time_period(first_stat, next_stat)
      users_generating_karma = User.count(:conditions => "id IN (SELECT user_id FROM comments WHERE deleted = 'f' AND date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}' UNION SELECT user_id FROM contents WHERE date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}')")
      active_factions_portals = User.db_query("SELECT count(*) FROM stats.portals WHERE date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}' AND karma > 0 AND portal_id IN (SELECT id FROM portals WHERE type='FactionsPortal')")[0]['count']
      active_clans_portals = User.db_query("SELECT count(*) FROM stats.portals WHERE date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}' AND karma > 0 AND portal_id IN (SELECT id FROM portals WHERE type='ClansPortal')")[0]['count']
      completed_competitions_matches = CompetitionsMatch.count(:conditions => ["date_trunc('day', completed_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}'"])
      #proxy_errors = `grep -c "All workers are in error state" #{Rails.root}/log/error-#{first_stat.strftime('%Y%m%d')}.log`.strip
      proxy_errors = 0 #if proxy_errors.strip == ''
      dbsize = User.db_query("SELECT pg_database_size('#{ActiveRecord::Base.configurations[Rails.env]['database']}');")[0]['pg_database_size']
      requests = User.db_query("SELECT count(*) FROM stats.pageloadtime WHERE date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}'")[0]['count']
      http_500 = User.db_query("SELECT count(*) FROM stats.pageloadtime WHERE date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}' AND http_status = 500")[0]['count']
      http_401 = User.db_query("SELECT count(*) FROM stats.pageloadtime WHERE date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}' AND http_status = 401")[0]['count']
      http_404 = User.db_query("SELECT count(*) FROM stats.pageloadtime WHERE date_trunc('day', created_on) = '#{first_stat.strftime('%Y-%m-%d 00:00:00')}' AND http_status = 404")[0]['count']
      User.db_query("INSERT INTO stats.general(created_on) VALUES('#{cur_str}')") if User.db_query("SELECT * FROM stats.general WHERE created_on = '#{cur_str}'").size == 0

      User.db_query("UPDATE stats.general
                    SET new_comments = '#{Gmstats.comments_created_in_time_period(first_stat, next_stat)}',
                        users_total = '#{Gmstats.users(:total, next_stat)}',
                        users_confirmed = '#{Gmstats.users(:confirmed, next_stat)}',
                        users_unconfirmed = '#{Gmstats.users(:unconfirmed, next_stat)}',
                        users_unconfirmed_1w = '#{Gmstats.users(:unconfirmed_1w, next_stat)}',
                        users_unconfirmed_2w = '#{Gmstats.users(:unconfirmed_2w, next_stat)}',
                        users_active = '#{Gmstats.users(:active, next_stat)}',
                        users_shadow = '#{Gmstats.users(:shadow, next_stat)}',
                        users_resurrected = '#{Gmstats.users(:resurrected, next_stat)}',
                        users_zombie = '#{Gmstats.users(:zombie, next_stat)}',
                        users_deleted = '#{Gmstats.users(:deleted, next_stat)}',
                        users_banned = '#{Gmstats.users(:banned, next_stat)}',
                        users_disabled = '#{Gmstats.users(:disabled, next_stat)}',
                        users_generating_karma = '#{users_generating_karma}',
                        new_clans = '#{created_clans}',
                        database_size = '#{dbsize}',
                        sent_emails = '#{sent_emails}',
                        downloaded_downloads_count = '#{downloaded_downloads_count}',
                        avg_page_render_time = #{avg_page_render_time},
                        stddev_page_render_time = #{stddev_page_render_time},
                        avg_db_queries_per_request = #{avg_db_queries_per_request},
                        stddev_db_queries_per_request = #{stddev_db_queries_per_request},
                        new_closed_topics = '#{new_closed_topics}',
                        new_clans_portals = '#{new_clans_portals}',
                        active_factions_portals = '#{active_factions_portals}',
                        active_clans_portals = '#{active_clans_portals}',
                        karma_per_user = '#{karma_diff.to_f / (users_generating_karma+0.1)}',
                        faith_diff = '#{faith_diff}',
                        requests = '#{requests}',
                        karma_diff = '#{karma_diff}',
                        proxy_errors = '#{proxy_errors}',
                        new_factions = '#{new_factions}',
                        http_500 = '#{http_500}',
                        http_401 = '#{http_401}',
                        http_404 = '#{http_404}',
                        completed_competitions_matches = #{completed_competitions_matches},
                        refered_hits = '#{Gmstats.refered_hits_in_time_period(first_stat, next_stat)}'
                  WHERE created_on = '#{cur_str}'")
      first_stat = next_stat
    end
  end
end
