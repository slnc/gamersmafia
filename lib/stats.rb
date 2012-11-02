# -*- encoding : utf-8 -*-
require 'set'

module Stats

  def self.update_general_stats
    # buscamos fecha más antigua de comentario
    # buscamos fecha más antigua en stats globales que tenga info de comentarios creados
    # actualizamos desde dicha fecha hasta ayer
    yesterday = 1.day.ago.beginning_of_day
    tonight = yesterday.advance(:days => 1)
    first_comment = User.db_query(
        "SELECT min(created_on) FROM comments")[0]['min'].to_time
    first_stat = User.db_query(
        "SELECT MAX(created_on) FROM stats.general WHERE new_comments IS NOT NULL")[0]['max']
    first_stat = (first_stat.to_s != '') ? first_stat.to_time : first_comment
    # nos ponemos en el primer día que tenemos que calcular
    first_stat.advance(:days => 1).beginning_of_day
    first_stat = 1.day.ago.beginning_of_day if Rails.env == 'test'

    while first_stat < tonight
      cur_str = first_stat.strftime('%Y-%m-%d')
      next_stat = first_stat.advance(:days => 1)
      sql_created_on = (
          "created_on::date = '#{first_stat.strftime('%Y-%m-%d')}'::date)")
      created_clans = Clan.count(
          :conditions => "created_on::date '#{first_stat.strftime('%Y-%m-%d')}'::date)")
      new_closed_topics = Topic.published.count(
          :conditions => "closed = 't' AND updated_on::date = '#{first_stat.strftime('%Y-%m-%d')}'::date")
      new_clans_portals = ClansPortal.count(
          :conditions => "clan_id IS NOT NULL AND #{sql_created_on}")
      dbrender = User.db_query(
          "SELECT
             avg(time),
             stddev(time),
             avg(db_queries) as avg_dbq,
             stddev(db_queries) as stddev_dbq
           FROM stats.pageloadtime
           WHERE #{sql_created_on}")[0]
      new_factions = Faction.count(:conditions => sql_created_on)
      sent_emails = SentEmail.count(:conditions => sql_created_on)
      downloaded_downloads_count = DownloadedDownload.count(
          :conditions => sql_created_on)
      avg_page_render_time = dbrender['avg'].to_f
      stddev_page_render_time = dbrender['stddev'].to_f
      avg_db_queries_per_request = dbrender['avg_dbq'].to_f
      stddev_db_queries_per_request = dbrender['stddev_dbq'].to_f
      karma_diff = Gmstats.karma_in_time_period(first_stat, next_stat)
      users_generating_karma = User.count(
          :conditions => "id IN (
                            SELECT user_id
                            FROM comments
          WHERE deleted = 'f'
          AND #{sql_created_on}

          UNION

          SELECT user_id
          FROM contents
          WHERE #{sql_created_on})")
      active_factions_portals = User.db_query(
          "SELECT count(*)
           FROM stats.portals
           WHERE #{sql_created_on}
           AND karma > 0
           AND portal_id IN (
             SELECT id
             FROM portals
             WHERE type='FactionsPortal')")[0]['count']
      active_clans_portals = User.db_query(
          "SELECT count(*)
           FROM stats.portals
           WHERE #{sql_created_on}
           AND karma > 0
           AND portal_id IN (
             SELECT id
             FROM portals
             WHERE type='ClansPortal')")[0]['count']
      completed_competitions_matches = CompetitionsMatch.count(
          :conditions => sql_created_on)
      #proxy_errors = `grep -c "All workers are in error state" #{Rails.root}/log/error-#{first_stat.strftime('%Y%m%d')}.log`.strip
      proxy_errors = 0 #if proxy_errors.strip == ''
      dbsize = User.db_query("SELECT pg_database_size('#{ActiveRecord::Base.configurations[Rails.env]['database']}');")[0]['pg_database_size']
      requests = User.db_query("SELECT count(*) FROM stats.pageloadtime WHERE #{sql_created_on}")[0]['count']
      http_500 = User.db_query("SELECT count(*) FROM stats.pageloadtime WHERE #{sql_created_on} AND http_status = 500")[0]['count']
      http_401 = User.db_query("SELECT count(*) FROM stats.pageloadtime WHERE #{sql_created_on} AND http_status = 401")[0]['count']
      http_404 = User.db_query("SELECT count(*) FROM stats.pageloadtime WHERE #{sql_created_on} AND http_status = 404")[0]['count']
      if User.db_query("SELECT * FROM stats.general WHERE created_on = '#{cur_str}'").size == 0
        User.db_query("INSERT INTO stats.general(created_on) VALUES('#{cur_str}')")
      end

      User.db_query(
          "UPDATE stats.general
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

  module Factions
    def self.oldest_day_without_stats
      dbmaxstats = User.db_query(
          "SELECT MAX(created_on) FROM stats.portals")[0]
      if dbmaxstats['max'].to_i == 0
        # no stats
        min_time = [
          Content.published.find(:first, :order => 'created_on').created_on,
          Comment.find(:first, :order => 'created_on').created_on,
        ].min
      else
        min_time = dbmaxstats['max'].to_time
      end
      min_time = min_time.yesterday.beginning_of_day
      min_time = 1.day.ago.beginning_of_day if Rails.env == 'test'
      min_time
    end

    def self.update_factions_stats
      min_time = self.oldest_day_without_stats
      today = Time.now.beginning_of_day

      while min_time < today
        min_time_strted = min_time.strftime('%Y-%m-%d %H:%M:%S')

        portals_stats = {}
        games_r_portals = {}
        gaming_platforms_r_portals = {}
        bazar_districts_r_portals = {}
        clans_r_portals = {}
        general = 0

        portal_stats = Karma.karma_points_by_portal(
            min_time.advance(:days - Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS))

        begin
          User.db_query(
              "INSERT INTO stats.portals(created_on, portal_id, karma)
               VALUES ('#{min_time.strftime('%Y-%m-%d')}', NULL, #{general})")
        rescue Exception
          User.db_query(
              "UPDATE stats.portals
               SET karma = #{general}
               WHERE created_on = '#{min_time.strftime('%Y-%m-%d')}'
               AND portal_id IS NULL")
        end

        User.db_query(
            "INSERT INTO stats.portals(
               portal_id,
               karma,
               created_on,
               pageviews,
               visits,
               unique_visitors,
               unique_visitors_reg)
             SELECT id,
               0,
               '#{min_time.strftime('%Y-%m-%d')}',
               0,
               0,
               0,
               0
               FROM portals
               WHERE id NOT IN (
                 SELECT portal_id
                 FROM stats.portals
                 WHERE portal_id IS NOT NULL
                 AND created_on = '#{min_time.strftime('%Y-%m-%d')}')")
        # Ponemos a 0 las estadísticas del resto de portales
        # TODO cuando el campo created_on de portals represente fielmente el
        # nacimiento de un portal esto se puede optimizar

        Portal.find(:all).each do |portal|
          portal_id = portal.id
          karma = portals_stats[portal_id] ? portals_stats[portal_id] : 0
          dbrstats_visits = User.db_query(
              "SELECT
                 COUNT(*) as pageviews,
                 COUNT(DISTINCT(session_id)) as visits,
                 COUNT(DISTINCT(visitor_id)) as unique_visitors,
                 COUNT(DISTINCT(user_id)) as unique_visitors_reg
               FROM stats.pageviews
               WHERE created_on::timestamp
               BETWEEN '#{min_time_strted}'::timestamp
               AND '#{min_time_strted}'::timestamp + '1 day'::interval - '1 second'::interval
               AND portal_id = #{portal_id}")[0]

          pageviews = dbrstats_visits['pageviews']
          visits = dbrstats_visits['visits']
          unique_visitors = dbrstats_visits['unique_visitors']
          unique_visitors_reg = dbrstats_visits['unique_visitors_reg']

          User.db_query(
              "UPDATE stats.portals
               SET karma = #{karma},
                 pageviews = #{pageviews},
                 visits = #{visits},
                 unique_visitors = #{unique_visitors},
                 unique_visitors_reg = #{unique_visitors_reg}
               WHERE created_on = '#{min_time.strftime('%Y-%m-%d')}'
               AND portal_id = #{portal_id}")
        end
        min_time = min_time.advance(:days => 1)
      end
    end
  end

  module Portals
    def self.participation(portal, s, e)
      # devuelve el numero de personas diferentes que han participado en dicho
      # portal (en cuanto a karma) en el intervalo dado
    end

    # Returns Array where each element is an int with the karma generated on
    # that given day. [0] is the furthest day in the requested interval.
    def self.daily_karma(portal, s, e)
      sql_created = "created_on BETWEEN '#{s.strftime('%Y-%m-%d')}'
                                    AND '#{e.strftime('%Y-%m-%d')}'"
      User.db_query(
          "SELECT karma
             FROM stats.portals
            WHERE portal_id = #{portal.id}
              AND #{sql_created}
         ORDER BY created_on").collect { |dbr| dbr['karma'].to_i }
    end

    def self.daily_pageviews(portal, s, e)
      sql_created = "created_on BETWEEN '#{s.strftime('%Y-%m-%d')}' AND '#{e.strftime('%Y-%m-%d')}'"
      User.db_query("SELECT pageviews FROM stats.portals WHERE portal_id = #{portal.id} AND #{sql_created} ORDER BY created_on").collect { |dbr| dbr['pageviews'].to_i }
    end

    def self.update_portals_hits_stats
      User.db_query("SELECT count(*),
                          portal_id
                     FROM stats.pageviews
                    WHERE portal_id > 0
                      AND created_on >= now() - '1 month'::interval
                 GROUP BY portal_id").each do |dbr|
        portal = Portal.find_by_id(dbr['portal_id'])
        if portal.nil?
          Rails.logger.warn(
            "daily.update_portals_hits_stats(). Warning, portal id" +
            " #{dbr['portal_id']} (#{dbr['count']} pageviews) not found")
        else
          portal.cache_recent_hits_count = dbr['count'].to_i
          portal.save
        end
      end
      CacheObserver.expire_fragment("/common/gnav/#{Time.now.strftime('%Y-%m-%d')}")
    end
  end

  module Ads
    def self.last_update
      dbr = User.db_query("SELECT created_on FROM stats.ads_daily ORDER BY id DESC limit 1")
      dbr.size > 0 ? dbr[0]['created_on'] : 'desconocido'
    end
  end

  module Metrics
    ALL_METRICS = [
        "kpi.core.active_users_30d",
        "http.global.errors.external_404",
        "http.global.errors.internal_404",
        "http.global.errors.500",
    ]

    # Computes 30d active users from 30d ago to eod of date arg.
    def self.get_metric_last_30d(metric, date)
      out = []
      30.times do |days|
        date_string = date.advance(:days => -days).strftime("%Y%m%d")
        value = Keystore.get("#{metric}.#{date_string}")
        out.append((value || -1).to_i)
      end
      out.reverse
    end

    def self.get_metric_last_12m(metric, date)
      out = []
      12.times do |months|
        date_string = date.advance(:months => -months).strftime("%Y%m")
        value = Keystore.get("#{metric}.#{date_string}")
        out.append((value || -1).to_i)
      end
      out.reverse
    end

    def self.compute_daily_metrics(date)
      timestamp_end = date.end_of_day
      timestamp_start = timestamp_end.advance(:days => -30).beginning_of_day
      active_users_30d = self.active_users(timestamp_start, timestamp_end)
      Keystore.set("kpi.core.active_users_30d.#{date.strftime("%Y%m%d")}",
                   active_users_30d)

      date_before = date.beginning_of_day.advance(:days => -1).beginning_of_day

      if date.strftime("%Y-%m") != date_before.strftime("%Y-%m")
        (monthly_avg, monthly_sd) = self.compute_monthly_metric(
            "kpi.core.active_users_30d", date_before)
        Keystore.set("kpi.core.active_users_30d.avg.#{date.strftime("%Y%m")}",
                     monthly_avg)
        Keystore.set("kpi.core.active_users_30d.sd.#{date.strftime("%Y%m")}",
                     monthly_sd)
      end

      if date.strftime("%Y") != date_before.strftime("%Y")
        (yearly_avg, yearly_sd) = self.compute_yearly_metric(
            "kpi.core.active_users_30d", date_before)
        Keystore.set("kpi.core.active_users_30d.avg.#{date.strftime("%Y")}",
                     yearly_avg)
        Keystore.set("kpi.core.active_users_30d.sd.#{date.strftime("%Y")}",
                     yearly_sd)
      end
    end

    def self.compute_monthly_metric(metric, date)
      end_of_month = date.end_of_month
      self.compute_metric_days_back(end_of_month, end_of_month.mday, metric)
    end

    def self.compute_yearly_metric(metric, date)
      end_of_year = date.end_of_year
      self.compute_metric_days_back(end_of_year, end_of_year.yday, metric)
    end

    def self.compute_metric_days_back(end_date, days_back, metric)
      values = []
      days_back.times do |days|
        cur_date = end_date.advance(:days => -days)
        values.append(
            Keystore.get("#{metric}.#{cur_date.strftime("%Y%m%d")}").to_i)
      end
      values.compact!
      if values.size < days_back
        Rails.logger.warn(
            "compute_metric_days_back(#{end_date}, #{days_back}, #{metric})" +
            " expected #{days_back} data points but found #{values.size}")
      end

      if values.size == 0
        [0, 0]
      else
        [values.mean, Math.standard_deviation(values)]
      end
    end

    # Computes 30d active users from 30d ago to eod of date arg.
    def self.active_users(timestamp_start, timestamp_end)
      if timestamp_start > timestamp_end
        (timestamp_start, timestamp_end) = timestamp_end, timestamp_start
      end

      conditions = [
          "created_on >= ? AND created_on <= ?", timestamp_start, timestamp_end]

      users = Set.new
      users.merge(BetsTicket.count(
          :all, :conditions => conditions, :group => :user_id).keys)
      users.merge(Content.count(
          :all, :conditions => conditions, :group => :user_id).keys)
      users.merge(ContentRating.count(
          :all, :conditions => conditions, :group => :user_id).keys)
      users.merge(ContentsRecommendation.count(
          :all, :conditions => conditions, :group => :sender_user_id).keys)
      users.merge(Comment.count(
          :all, :conditions => conditions, :group => :user_id).keys)
      users.merge(CommentsValoration.count(
          :all, :conditions => conditions, :group => :user_id).keys)
      users.merge(Message.count(
          :all, :conditions => conditions, :group => :user_id_from).keys)
      users.merge(PollsVote.count(
          :all, :conditions => conditions, :group => :user_id).keys)
      users.merge(PublishingDecision.count(
          :all, :conditions => conditions, :group => :user_id).keys)
      users.merge(Alert.count(
          :all,
          :conditions => ["completed_on >= ? AND completed_on <= ?",
                          timestamp_start, timestamp_end],
          :group => :reviewer_user_id).keys)
      users.merge(TrainingQuestion.count(
          :all, :conditions => conditions, :group => :user_id).keys)
      users.merge(UsersContentsTag.count(
          :all, :conditions => conditions, :group => :user_id).keys)
      users.size
    end

    def self.mdata(metric, s, e, trunc='day')
      const_get(metric).new.data(s, e, trunc)
    end

    class Base
      def data(tstart, tend, trunc)
        _data(tstart, tend, trunc)
      end

      protected
      # select (current_date - '31 days'::interval)::date + s.t as dates from generate_series(0,31) as s(t);
      def sql_time(s, e)
        "created_on BETWEEN '#{s.strftime('%Y-%m-%d')}' AND '#{e.strftime('%Y-%m-%d')}'"
      end
    end
    """
    SELECT series.date,
           count(date_trunc('day', content_ratings.created_on))
      from (select generate_series(0,31) + '2008-05-05'::date as date) as series
 left outer join content_ratings on series.date = date_trunc('day', content_ratings.created_on)
 where content_ratings.created_on between '2008-05-05 00:00:00'::timestamp and ('2008-05-05 00:00:00'::timestamp + '4 days'::interval)::timestamp
 GROUP BY series.date
 ORDER BY series.date;


    select (current_date - '31 days'::interval)::date + s.t as dates,
           (select count(*) FROM users WHERE date_trunc('day', created_on) = s(t))
      from generate_series(0,31) as s(t);


select date_trunc('day', created_on),
       count(*),
       (current_date - '31 days'::interval)::date + s.t as date
  from users
right join generate_series(0,31) as s(t) on (date_trunc('day', created_on) = (current_date - '31 days'::interval)::date + s.t)
 where created_on >= now() - '31 days'::interval
group by date_trunc('day', created_on) order by s asc
"""

    class NewUsers < Base
      def _data(s, days, trunc)
        User.db_query("SELECT count(*),
                              date_trunc('#{trunc}', created_on)
                         FROM users
                        WHERE #{sql_time(s, e)}
                     GROUP BY date_trunc('day', created_on)
                     ORDER BY date_trunc('day', created_on) ASC")


        User.db_query("select date, sum(count) from (
                     select generate_series(0,#{days}) + current_date - '#{days} days'::interval as date, 0 as count
                     UNION
                     select date_trunc('day', created_on)::date as date, count(*)
                       FROM #{t_name}
                      where created_on between '2008-05-05 00:00:00'::timestamp
                                           and ('2008-05-05 00:00:00'::timestamp + '31 days'::interval)::timestamp
                    group by date_trunc('day', created_on)::date

                    order by date, count) as a group by date")

        if nil then
          User.db_query("select date, sum(count) from (select generate_series(0,31) + '2008-05-05'::date as date, 0 as count
                     UNION
                     select date_trunc('day', created_on)::date as date, count(*)
                       FROM content_ratings
                      where created_on between '2008-05-05 00:00:00'::timestamp
                                           and ('2008-05-05 00:00:00'::timestamp + '31 days'::interval)::timestamp
                    group by date_trunc('day', created_on)::date

                    order by date, count) as a group by date")
        end




        User.db_query("explain analyze select series.date,
           COALESCE(count(date_trunc('day', content_ratings.created_on)), 0)
      from (select generate_series(0,31) + '2008-05-05'::date as date) as series
 left outer join content_ratings on series.date = date_trunc('day', content_ratings.created_on)::date
 group by series.date
 order by series.date")
      end
    end

    class NewConfirmedUsers

    end

    class RatioCompletedRegistrations

    end
  end


  def self.advertiser_daily_hits_in_timestamp(tstart, tend, advertiser)
    tstart, tend = tend, tstart if tstart > tend
    sql_created_on = "created_on BETWEEN '#{tstart.strftime('%Y-%m-%d')}' AND '#{tend.strftime('%Y-%m-%d')}'"
    User.db_query("select sum(hits),
                            created_on
                       from stats.ads_daily
                      WHERE ads_slots_instance_id IN (SELECT id
                                           FROM ads_slots_instances
                                          WHERE deleted='f'
                                            AND ad_id IN (select id from ads where advertiser_id = #{advertiser.id}))
                        AND #{sql_created_on}
                   GROUP BY created_on
                   ORDER BY created_on asc").collect { |dbr| dbr['sum'].to_i }
  end

  def self.adsi_impressions_in_timestamp(tstart, tend, adsi)
    sql_created_on = "created_on BETWEEN '#{tstart}' AND '#{tend}'"
    User.db_query("SELECT sum(pageviews)
                           FROM stats.ads_daily
                          WHERE ads_slots_instance_id = #{adsi.id}
                            AND #{sql_created_on}")[0]['sum'].to_i
  end

  def self.ad_hits_in_timestamp(tstart, tend, ad)
    raise "DEPRECATED"
    sql_created_on = "created_on BETWEEN '#{tstart}' AND '#{tend}'"
    User.db_query("SELECT count(*)
                           FROM stats.ads
                          WHERE element_id = 'ad#{ad.id}'
                            AND #{sql_created_on}")[0]['count'].to_i
  end

  def self.adsi_hits_in_timestamp(tstart, tend, adsi)
    # Hits = clicks
    sql_created_on = "created_on BETWEEN '#{tstart}' AND '#{tend}'"
    # aqui todavia no tenemos la info consolidada
    User.db_query("SELECT count(*)
                           FROM stats.ads
                          WHERE element_id = 'adsi#{adsi.id}'
                            AND #{sql_created_on}")[0]['count'].to_i
  end

  def self.consolidated_adsi_hits_in_timestamp(tstart, tend, adsi)
    sql_created_on = "created_on BETWEEN '#{tstart}' AND '#{tend}'"

    User.db_query("SELECT sum(hits)
                           FROM stats.ads_daily
                          WHERE ads_slots_instance_id = #{adsi.id}
                            AND #{sql_created_on}")[0]['sum'].to_i
  end

  def self.adsi_by_portals_in_tstamp(tstart, tend, advertiser)
    sql_created_on_alias = "a.created_on BETWEEN '#{tstart}' AND '#{tend}'"
    total = total_advertiser_clicks_in_timerange(tstart, tend, advertiser)
    sum = 0
    res = User.db_query("SELECT count(*),
                         b.name as name,
                         a.portal_id
                    FROM stats.ads a
               LEFT JOIN portals b on a.portal_id = b.id
                   WHERE element_id IN (SELECT 'adsi' || a.id
                                           FROM ads_slots_instances a
                                           JOIN ads b on a.ad_id = b.id
                                          WHERE b.advertiser_id = #{advertiser.id})
                     AND (portal_id in (-1, -2, -3) OR type = 'FactionsPortal')
                     AND #{sql_created_on_alias}
                GROUP BY b.name,
                         a.portal_id
                ORDER BY count(*) desc").collect do |dbr|
      sum += dbr['count'].to_i
      if dbr['portal_id'] == '-1'
        dbr['name'] = 'gamersmafia.com'
      elsif dbr['portal_id'] == '-2'
        dbr['name'] = 'bazar.gamersmafia.com'
      elsif dbr['portal_id'] == '-3'
        dbr['name'] = 'arena.gamersmafia.com'
      end
      dbr
    end
    res<< {'name' => 'gamersmafia.com', 'count' => total - sum }
    res
  end

  def self.adsi_info_in_tstamp(tstart, tend, ad)
    #ad es realmente un ads_slots_instance
    sql_created_on = "created_on BETWEEN '#{tstart}' AND '#{tend}'"
    adhits = consolidated_adsi_hits_in_timestamp(tstart, tend, ad)
    pageviews = adsi_impressions_in_timestamp(tstart, tend, ad)
    result = {:hits => adhits, :pageviews => pageviews, :ctr => adhits/(pageviews+0.1), :daily_hits => nil}

    db_daily_hits = User.db_query("select hits,
                            created_on as date
                       from stats.ads_daily
                      where ads_slots_instance_id = #{ad.id}
                        AND #{sql_created_on}
                   ORDER BY created_on asc")
    db_all_daily = User.db_query("select generate_series(0,#{((tstart.to_i - tend.to_i) / 86400).ceil}) + '#{tstart.strftime('%Y-%m-%d')}'::date as date, 0 as count")
    db_daily_hits_h = {}
    db_all_daily.collect { |dbr| db_daily_hits_h[dbr['date']] = dbr['count'].to_i }
    db_daily_hits.collect { |dbr| db_daily_hits_h[dbr['date']] = dbr['hits'].to_i }

    result[:daily_hits] = db_daily_hits_h.values
    #.collect { |dbr| dbr['count'].to_i }
    result
  end

  def self.ad_info_in_tstamp(tstart, tend, ad)
    raise "DEPRECATED"
    sql_created_on = "created_on BETWEEN '#{tstart}' AND '#{tend}'"
    adhits = ad_hits_in_timestamp(tstart, tend, ad)
    pageviews = ad_impressions_in_timestamp(tstart, tend, ad)
    result = {:hits => adhits, :pageviews => pageviews, :ctr => adhits/(pageviews+0.1), :daily_hits => nil}

    db_daily_hits = User.db_query("select count(*),
                            date_trunc('day', created_on)::date as date
                       from stats.ads
                      where element_id = 'ad#{ad.id}'
                        AND #{sql_created_on}
                   GROUP BY date_trunc('day', created_on)::date
                   ORDER BY date_trunc('day', created_on)::date asc")
    db_all_daily = User.db_query("select generate_series(0,#{((tstart.to_i - tend.to_i) / 86400).ceil}) + '#{tstart.strftime('%Y-%m-%d')}'::date as date, 0 as count")
    db_daily_hits_h = {}
    db_all_daily.collect { |dbr| db_daily_hits_h[dbr['date']] = dbr['count'].to_i }
    db_daily_hits.collect { |dbr| db_daily_hits_h[dbr['date']] = dbr['count'].to_i }

    result[:daily_hits] = db_daily_hits_h.values
    #.collect { |dbr| dbr['count'].to_i }
    result
  end

  def self.generate_daily_ads_stats
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
  end


  def self.total_advertiser_clicks_in_timerange(tstart, tend, advertiser)
    sql_created_on = "created_on BETWEEN '#{tstart.strftime('%Y-%m-%d')}' AND '#{tend.strftime('%Y-%m-%d')}'"
    total = User.db_query("SELECT sum(hits)
                     FROM stats.ads_daily
                    WHERE ads_slots_instance_id IN (SELECT id
                                           FROM ads_slots_instances
                                          WHERE deleted='f'
                                            AND ad_id IN (select id from ads where advertiser_id = #{advertiser.id}))
                      AND #{sql_created_on}")[0]['sum'].to_i
    total
  end

  class Goals
    def self.after_init
      self.available_goals << :partial_user_registrations
      self.available_goals << :ads_clicks
      self.available_goals << :topics_created
      self.available_goals << :questions_created
      self.available_goals << :comments_created
      self.available_goals << :contents_created
      self.available_goals_abbrv[:partial_user_registrations] = :pur
      self.available_goals_abbrv[:ads_clicks] = :adc
      self.available_goals_abbrv[:topics_created] = :tc
      self.available_goals_abbrv[:questions_created] = :qc
      self.available_goals_abbrv[:comments_created] = :cc
      self.available_goals_abbrv[:contents_created] = :conc
    end

    def self.questions_created(opts)
      contents_created({:content_type => 'Question'}.merge(opts))
    end

    def self.topics_created(opts)
      contents_created({:content_type => 'Topic'}.merge(opts))
    end

    def self.contents_created(opts)
      # opts[:content_type] indica la clase: News, Topic, si no se especifica cuenta todos los contenidos creados
      # es simplemente un clickthrough que usa otra tabla para las conversiones
      out = {}
      opts = {:total => true}.merge(opts)
      # raise "no se ha especificado content_type" unless opts[:content_type] && !ContentType.find_by_name(opts[:content_type]).nil?
      out[:treated_visitors] = self.treated_visitors(opts)

      # constraints básicas
      from_where_sql = date_constraints(opts)
      to_where_sql = date_constraints(opts)
      # FROM
      from_where_sql << visitor_id_constraint(opts)
      from_where_sql << " AND #{opts[:append_to_from_where_sql]}" if opts[:append_to_from_where_sql]

      to_where_sql << visitor_id_constraint(opts)

      # contabilizamos impresiones y conversiones
      count_sql = opts[:total] ? 'count(visitor_id)' :  'count(distinct(visitor_id))'

      out[:impressions] = User.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{from_where_sql}")[0]['count'].to_f

      out[:conversions] = User.db_query("SELECT count(id)
                                          FROM #{opts[:content_type] ? ActiveSupport::Inflector::tableize(opts[:content_type]) : 'contents'}
                                         WHERE #{date_constraints(opts)}
                                           AND state = #{Cms::PUBLISHED}
                                               #{user_id_constraint(opts)}")[0]['count'].to_f

      out[:rate] = out[:conversions] / (out[:impressions]  > 0 ? out[:impressions] : 1)
      out
    end

    def self.comments_created(opts)
      # es simplemente un clickthrough que usa otra tabla para las conversiones
      out = {}
      opts = {:total => true}.merge(opts)
      out[:treated_visitors] = self.treated_visitors(opts)

      # constraints básicas
      from_where_sql = date_constraints(opts)
      to_where_sql = date_constraints(opts)
      # FROM
      from_where_sql << visitor_id_constraint(opts)
      from_where_sql << " AND #{opts[:append_to_from_where_sql]}" if opts[:append_to_from_where_sql]

      to_where_sql << visitor_id_constraint(opts)

      # contabilizamos impresiones y conversiones
      count_sql = opts[:total] ? 'count(visitor_id)' :  'count(distinct(visitor_id))'

      out[:impressions] = User.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{from_where_sql}")[0]['count'].to_f

      out[:conversions] = User.db_query("SELECT count(id)
                               FROM comments
                              WHERE deleted = \'f\'
                                AND #{date_constraints(opts)}
                                    #{user_id_constraint(opts)}")[0]['count'].to_f

      out[:rate] = out[:conversions] / (out[:impressions]  > 0 ? out[:impressions] : 1)
      out
    end

    def self.user_registrations(opts)
      out = {}
      opts = {:total => false}.merge(opts)
      out[:treated_visitors] = self.treated_visitors(opts)

      # constraints básicas
      from_where_sql = date_constraints(opts)
      to_where_sql = date_constraints(opts)
      # FROM
      from_where_sql << visitor_id_constraint(opts)
      from_where_sql << " AND #{opts[:append_to_from_where_sql]}" if opts[:append_to_from_where_sql]

      to_where_sql << visitor_id_constraint(opts)

      # contabilizamos impresiones y conversiones
      count_sql = opts[:total] ? 'count(visitor_id)' :  'count(distinct(visitor_id))'

      out[:impressions] = User.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{from_where_sql}")[0]['count'].to_f

      out[:conversions] = User.db_query("SELECT count(distinct(user_id) )
                               FROM stats.pageviews
                              WHERE 1 = 1 #{visitor_id_constraint(opts)}
                                AND #{date_constraints(opts)}
                                    ")[0]['count'].to_f

      out[:rate] = out[:conversions] / (out[:impressions]  > 0 ? out[:impressions] : 1)
      out
    end

    def self.partial_user_registrations(opts)
      # usuarios expuestos al tratamiento (no es necesario clickthrough) que hayan iniciado el proceso de registro
      #out = {}
      #out[:treated_visitors] = self.treated_visitors(opts)
      #dbinfo = User.db_query("SELECT count(distinct(visitor_id))
      #                              FROM stats.pageviews as parent
      #                             WHERE #{date_constraints(opts)}
      #                                   #{visitor_id_constraint(opts)}
      #                               AND controller = 'cuenta'
      #                               AND action = 'alta'")[0]
      #out[:rate] = dbinfo['count'].to_f
      #out[:stddev] = dbinfo['count'].to_f # TODO esto no está bien
      #out
      clickthrough(opts.merge(
                              :append_to_from_where_sql => 'controller = \'cuenta\' AND action = \'alta\'',
      :append_to_to_where_sql => 'controller = \'cuenta\' AND action IN (\'create\', \'create2\')'))
    end

    def self.ads_clicks(opts)
      # es simplemente un clickthrough que usa otra tabla para las conversiones
      opts = {:total => true}.merge(opts)
      out = {}
      out[:treated_visitors] = self.treated_visitors(opts)

      # constraints básicas
      from_where_sql = date_constraints(opts)
      to_where_sql = date_constraints(opts)
      # FROM
      from_where_sql << visitor_id_constraint(opts)
      from_where_sql << " AND #{opts[:append_to_from_where_sql]}" if opts[:append_to_from_where_sql]

      to_where_sql << visitor_id_constraint(opts)

      # contabilizamos impresiones y conversiones
      count_sql = opts[:total] ? 'count(visitor_id)' :  'count(distinct(visitor_id))'

      out[:impressions] = User.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{from_where_sql}")[0]['count'].to_f

      out[:conversions] = User.db_query("SELECT #{count_sql}
                                          FROM stats.ads
                                         WHERE #{to_where_sql}")[0]['count'].to_f

      out[:rate] = out[:conversions] / (out[:impressions]  > 0 ? out[:impressions] : 1)
      out
    end
  end

  def self.online_users
    all_vars = GlobalVars.get_all_vars
    {"anonymous" => all_vars["online_anonymous"],
     "registered" => all_vars["online_registered"]}
  end


  def self.update_online_stats
    online_anonymous = User.db_query(
        "SELECT count(distinct(visitor_id))
           FROM stats.pageviews
          WHERE user_id IS NULL
            AND created_on >= now() - '30 minutes'::interval")[0]["count"].to_i

    online_registered = User.db_query(
        "SELECT count(*)
           FROM users
          WHERE lastseen_on >= now() - '30 minutes'::interval")[0]["count"].to_i

    GlobalVars.update_var("online_anonymous", online_anonymous)
    GlobalVars.update_var("online_registered", online_registered)
  end

  def self.register_referer(user_id, remote_ip, referer)
    referer = User.find(user_id)
    recent_same_ip_hits = User.db_query(
        "SELECT *
         FROM refered_hits
         WHERE ipaddr = '#{remote_ip}'
         AND created_on > now() - '10 minutes'::interval")
    if recent_same_ip_hits.length == 0
      User.db_query(
          "INSERT INTO refered_hits(user_id, ipaddr, referer)
           VALUES (#{user_id}, '#{remote_ip}',
             #{User.connection.quote(referer)})")
      # TODO chequear que las visitas referidas de nuestros propios dominios ni
      # de bots cuenten.
    end
  end

  def self.pageloadtime(request, seconds, response, controller_name, action_name, portal)
    #dbs = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.get_stats
    dbs = {:queries => 0, :rows => 0}
    db_queries = dbs[:queries]
    db_rows = dbs[:rows]
    # TODO(slnc): rails3 temporarily disabled pg stats

    response_status = response.headers['status'] ? response.headers['Status'].split(' ')[0]: '500'
    User.db_query("INSERT INTO stats.pageloadtime(http_status,
                                                  controller,
                                                  action,
                                                  time,
                                                  portal_id,
                                                  db_queries,
                                                  db_rows)
                                           VALUES(#{response_status},
                                                  '#{controller_name}',
                                                  '#{action_name}',
                                                  #{'%.5f' % seconds},
                                                  #{portal.id},
                                                  #{db_queries + 1},
                                                  #{db_rows});")
  end

  def self.consolidate_ads_daily_stats(tstart, tend)
    if User.db_query("SELECT count(*) FROM stats.ads_daily WHERE created_on = '#{tstart.strftime('%Y-%m-%d')}'")[0]['count'].to_i > 0 then
      Rails.logger.warn("Ya hay stats para #{tstart}, no recalculo")
      return
    end
    pageviews_by_ad_id = {}
    myre = /"([0-9]+)"/

    date_sql = "created_on BETWEEN '#{tstart.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{tend.strftime('%Y-%m-%d %H:%M:%S')}'"

    User.db_query("select count(*), ads_shown from stats.pageviews where #{date_sql} AND ads_shown IS NOT NULL group by ads_shown order by ads_shown").each do |dbr|
      dbr['ads_shown'].scan(myre).each do |ad_id|
        ad_id = ad_id[0]
        pageviews_by_ad_id[ad_id.to_i] ||= 0
        pageviews_by_ad_id[ad_id.to_i] += dbr['count'].to_i
      end
    end

    # ahora sacamos los hits del día
    # TODO
    # buscamos todos los instances de ads_slots del día

    AdsSlotsInstance.find(:all).each do |adsi|
      hits = Stats.adsi_hits_in_timestamp(tstart.strftime('%Y-%m-%d %H:%M:%S'), tend.strftime('%Y-%m-%d %H:%M:%S'), adsi)
      pageviews = pageviews_by_ad_id[adsi.id] ? pageviews_by_ad_id[adsi.id] : 0
      pageviews_div = (pageviews > 0) ? pageviews : 1
      User.db_query("INSERT INTO stats.ads_daily(ads_slots_instance_id, pageviews, hits, ctr, created_on) VALUES(#{adsi.id}, #{pageviews}, #{hits}, #{hits.to_f/pageviews_div}, '#{tstart.strftime('%Y-%m-%d')}')")
    end
  end

  def self.user_contents_by_type(u)
    #total_karma = 0.0
    result = {}

    sum_karma_comments = u.comments.count(:conditions => 'deleted = \'f\'')
    total_karma = sum_karma_comments.to_f
    result.add_if_val_in_topn('Comments', sum_karma_comments, 5)
    ContentType.find(:all).each do |ct|
      sum_karma_ct = Object.const_get(ct.name).count(:conditions => "user_id = #{u.id} AND state = #{Cms::PUBLISHED}")
      total_karma += sum_karma_ct
      result.add_if_val_in_topn(ct.name, sum_karma_ct, 5)
    end
    result['Otros'] = total_karma - result.values.sum
    fresult = {}
    result.keys.each do |k|
      fresult[k] = ((result[k] / total_karma) * 100)
    end
    fresult
  end

  def self.user_contents_by_portal(u)
    statz = {}
    User.db_query("SELECT count(*),
                          portal_id
                     FROM comments
                    WHERE user_id = #{u.id}
                      AND deleted = 'f'
                 GROUP BY portal_id").each do |dbr|
      statz[dbr['portal_id'].to_i] = dbr['count'].to_i * Karma::KPS_CREATE['Comment']
    end

    User.db_query("SELECT count(*),
                          portal_id,
                          content_type_id
                     FROM contents
                    WHERE user_id = #{u.id}
                      AND state = #{Cms::PUBLISHED}
                      AND source IS NULL
                 GROUP BY portal_id,
                          content_type_id").each do |dbr|
      statz[dbr['portal_id'].to_i]  ||= 0
      statz[dbr['portal_id'].to_i] += dbr['count'].to_i * Karma::KPS_CREATE[ContentType.find(dbr['content_type_id'].to_i).name]
    end

    User.db_query("SELECT count(*),
                          portal_id
                     FROM contents
                    WHERE user_id = #{u.id}
                      AND source IS NOT NULL
                      AND state = #{Cms::PUBLISHED}
                 GROUP BY portal_id").each do |dbr|
      statz[dbr['portal_id'].to_i]  ||= 0
      statz[dbr['portal_id'].to_i] += dbr['count'].to_i * Karma::KPS_CREATE['Copypaste']
    end

    statz2 = {}
    total= statz.values.sum.to_f
    statz.each do |k, v|
      statz2.add_if_val_in_topn(k, (v/total) * 100, 5)
    end
    statz2['Otros'] = ((total - statz2.values.sum) / total) * 100
    statz2
  end

  def self.user_contents_by_rating(u)
    res = {}
    User.db_query("SELECT count(*),
                          rating
                     FROM content_ratings
                     JOIN contents on content_ratings.content_id = contents.id
                    WHERE contents.user_id = #{u.id}
                GROUP BY rating").each do |dbr|
      res[dbr['rating'].to_i] = dbr['count'].to_i
    end
    tot = res.values.sum.to_f

    res2 = {}
    10.times do |i|
      i = i + 1

      if res[i]
        res2[i] = (res[i]/tot) * 100
      else
        res2[i] = 0
      end
    end

    res2
  end

  def self.update_users_daily_stats
    # AFTER update_users_karma_stats
    youngest_day = 15.days.ago.end_of_day  # included
    start_day = User.db_query("SELECT created_on
                                 FROM stats.users_daily_stats
                             ORDER BY created_on DESC LIMIT 1")
    if start_day.size > 0
      start_day = start_day[0]['created_on'].to_time.advance(:days => 1)
      if start_day < youngest_day
        cur_day = start_day
      else
        cur_day = youngest_day
      end
    else # no hay records, cogemos el más viejo
      cur_day = User.db_query(
          "SELECT created_on
            FROM contents
        ORDER BY created_on
           LIMIT 1")[0]['created_on'].to_time
    end

    while cur_day <= youngest_day
      # iteramos a través de todos los users que han creado contenidos o
      # comentarios hoy.
      pointz = {}

      User.find(:all, :conditions => "id IN (SELECT user_id
                                               FROM contents
                                              WHERE state = #{Cms::PUBLISHED}
                                                AND karma_points > 0
                                                AND date_trunc('day', created_on) = '#{cur_day.strftime('%Y-%m-%d')} 00:00:00' UNION
                                             SELECT user_id
                                               FROM comments
                                              WHERE deleted = 'f'
                                                AND karma_points > 0
                                                AND date_trunc('day', created_on) = '#{cur_day.strftime('%Y-%m-%d')} 00:00:00')").each do |u|
        # TODO here
        Karma.karma_points_of_user_at_date(u, cur_day).each do |portal_id, points|
          pointz[u.id] ||= {:karma => 0, :popularity => 0}
          pointz[u.id][:karma] += points
        end
      end

      # popularidad
      User.hot('all', cur_day.beginning_of_day, cur_day.end_of_day).each do |hinfo|
        pointz[hinfo[0].id] ||= {:karma => 0, :popularity => 0}
        pointz[hinfo[0].id][:popularity] = hinfo[1]
      end

      pointz.keys.each do |uid|
        v = pointz[uid]
        User.db_query(
            "INSERT INTO stats.users_daily_stats(user_id,
                                                 karma,
                                                 popularity,
                                                 created_on)
                  VALUES (#{uid},
                          #{v[:karma]},
                          #{v[:popularity]},
                          '#{cur_day.strftime('%Y-%m-%d')}')")
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
        User.db_query(
            "INSERT INTO stats.clans_daily_stats(
               clan_id,
               popularity,
               created_on)
             VALUES(
               #{uid},
               #{v[:popularity]},
               '#{cur_day.strftime('%Y-%m-%d')}')")
      end

      cur_day = cur_day.advance(:days => 1)
    end
  end

  def self.update_users_karma_stats
    max_day = 15.days.ago.end_of_day
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
      cur_day = User.db_query(
          "SELECT created_on
          FROM contents
          WHERE karma_points > 0
          ORDER BY created_on asc limit 1")[0]['created_on'].to_time
    end

    while cur_day <= max_day
      # iteramos a través de todos los users que han creado contenidos o
      # comentarios 14 días.
      User.find(:all,
                :conditions => "id IN (SELECT user_id
                                       FROM contents
                                       WHERE state = #{Cms::PUBLISHED}
                                       AND karma_points > 0
                                       AND date_trunc('day', created_on) = '#{cur_day.strftime('%Y-%m-%d')} 00:00:00' UNION
                                       SELECT user_id
                                       FROM comments
                                       WHERE deleted = 'f' AND karma_points > 0 AND date_trunc('day', created_on) = '#{cur_day.strftime('%Y-%m-%d')} 00:00:00')").each do |u|
        # TODO here
        Karma.karma_points_of_user_at_date(u, cur_day).each do |portal_id, points|
          User.db_query("INSERT INTO stats.users_karma_daily_by_portal(user_id, portal_id, karma, created_on) VALUES(#{u.id}, #{portal_id}, #{points}, '#{cur_day.strftime('%Y-%m-%d')}')")
        end
      end
      cur_day = cur_day.advance(:days => 1)
    end
  end

  def self.forget_old_pageviews
    User.db_query(
        "DELETE FROM stats.pageviews
         WHERE created_on <= now() - '3 months'::interval")
  end

  def self.user_comments_by_rating(u)
    res = {}
    User.db_query("SELECT sum(weight) as count,
                          comments_valorations_type_id
                     FROM comments_valorations
                     JOIN comments on comments_valorations.comment_id = comments.id
                    WHERE comments.user_id = #{u.id}
                GROUP BY comments_valorations_type_id").each do |dbr|
      res[dbr['comments_valorations_type_id'].to_i] = dbr['count'].to_i
    end
    tot = res.values.sum.to_f
    tot = 1 if tot == 0.0
    res2 = {}
    res.keys.each do |k|
      res2[k] = (res[k]/tot) * 100.0
    end
    res2
  end
end

class Hash
  # añade el par newk, newv al hash si el valor newv es mayor que cualquiera de los valores existentes
  # sirve para mantener un top
  def add_if_val_in_topn(newk, newv, n)
    if self.size <= n
      self[newk] = newv
    else
      self.keys.each do |k|
        if self[k] < newv
          self.delete(k)
          self[newk] = newv
          return
        end
      end
    end
  end
end
