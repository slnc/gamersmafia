module Stats
  module Portals
    def self.participation(portal, s, e)
      # devuelve el numero de personas diferentes que han participado en dicho portal (en cuanto a karma) en el intervalo dado
      
    end
    
    def self.daily_karma(portal, s, e)
      sql_created = "created_on BETWEEN '#{s.strftime('%Y-%m-%d')}' AND '#{e.strftime('%Y-%m-%d')}'"
      User.db_query("SELECT karma FROM stats.portals WHERE portal_id = #{portal.id} AND #{sql_created} ORDER BY created_on").collect { |dbr| dbr['karma'].to_i }
    end
    
    def self.daily_pageviews(portal, s, e)
      sql_created = "created_on BETWEEN '#{s.strftime('%Y-%m-%d')}' AND '#{e.strftime('%Y-%m-%d')}'"
      User.db_query("SELECT pageviews FROM stats.portals WHERE portal_id = #{portal.id} AND #{sql_created} ORDER BY created_on").collect { |dbr| dbr['pageviews'].to_i }
    end
  end
  
  module Ads
    def self.last_update
      dbr = User.db_query("SELECT created_on FROM stats.ads_daily ORDER BY id DESC limit 1")
      dbr.size > 0 ? dbr[0]['created_on'] : 'desconocido'
    end
  end
  
  module Metrics
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
    select series.date, 
           count(date_trunc('day', content_ratings.created_on))
      from (select generate_series(0,31) + '2008-05-05'::date as date) as series
 left outer join content_ratings on series.date = date_trunc('day', content_ratings.created_on)
 where content_ratings.created_on between '2008-05-05 00:00:00'::timestamp and ('2008-05-05 00:00:00'::timestamp + '4 days'::interval)::timestamp
 group by series.date
 order by series.date;
    
    
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
    Dbs.db_query("SELECT count(*)
                           FROM stats.ads
                          WHERE element_id = 'ad#{ad.id}'
                            AND #{sql_created_on}")[0]['count'].to_i
  end
  
  def self.adsi_hits_in_timestamp(tstart, tend, adsi)
    # Hits = clicks
    sql_created_on = "created_on BETWEEN '#{tstart}' AND '#{tend}'"
    # aqui todavia no tenemos la info consolidada
    Dbs.db_query("SELECT count(*)
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
    res = Dbs.db_query("SELECT count(*), 
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
    
    db_daily_hits = Dbs.db_query("select count(*), 
                            date_trunc('day', created_on)::date as date 
                       from stats.ads 
                      where element_id = 'ad#{ad.id}' 
                        AND #{sql_created_on}
                   GROUP BY date_trunc('day', created_on)::date 
                   ORDER BY date_trunc('day', created_on)::date asc") 
    db_all_daily = Dbs.db_query("select generate_series(0,#{((tstart.to_i - tend.to_i) / 86400).ceil}) + '#{tstart.strftime('%Y-%m-%d')}'::date as date, 0 as count")
    db_daily_hits_h = {}
    db_all_daily.collect { |dbr| db_daily_hits_h[dbr['date']] = dbr['count'].to_i }
    db_daily_hits.collect { |dbr| db_daily_hits_h[dbr['date']] = dbr['count'].to_i }
    
    result[:daily_hits] = db_daily_hits_h.values 
    #.collect { |dbr| dbr['count'].to_i }
    result
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
  
  def self.account_ad_impression(request, element_id, user_id, portal_id)
    user_id = user_id ? user_id : 'NULL'
    element_id = (/([a-zA-Z0-9_-])/ =~ element_id) ? element_id : 'NULL'
    user_agent = (request.user_agent.to_s != '') ? request.user_agent : ''
    referer = request.env['HTTP_REFERER'] ? request.env['HTTP_REFERER'] : ''
    url = request.request_uri
    ip = request.remote_ip
    if nil
      User.db_query("INSERT INTO stats.ads_shown (referer,
                                          user_id,
                                          ip,
                                          user_agent,
                                          portal_id,
                                          url,
                                          element_id)
                                   VALUES (#{User.connection.quote(referer)},
                                            #{user_id},
                                            '#{ip}',
                                            #{User.connection.quote(user_agent)},
                                            #{portal_id},
                                            #{User.connection.quote(url)},
                                            '#{element_id}')")
    end
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
      
      out[:impressions] = Dbs.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{from_where_sql}")[0]['count'].to_f
      
      out[:conversions] = Dbs.db_query("SELECT count(id) 
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
      
      out[:impressions] = Dbs.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{from_where_sql}")[0]['count'].to_f
      
      out[:conversions] = Dbs.db_query("SELECT count(id) 
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
      
      out[:impressions] = Dbs.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{from_where_sql}")[0]['count'].to_f
      
      out[:conversions] = Dbs.db_query("SELECT count(distinct(user_id) )
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
      #dbinfo = Dbs.db_query("SELECT count(distinct(visitor_id))
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
      
      out[:impressions] = Dbs.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{from_where_sql}")[0]['count'].to_f
      
      out[:conversions] = Dbs.db_query("SELECT #{count_sql}
                                          FROM stats.ads
                                         WHERE #{to_where_sql}")[0]['count'].to_f
      
      out[:rate] = out[:conversions] / (out[:impressions]  > 0 ? out[:impressions] : 1)
      out
    end
  end
  
  def self.online_users
    User.db_query("SELECT online_anonymous as anonymous, online_registered as registered FROM global_vars")[0]
  end
  
  
  def self.update_online_stats
    online_anon = Dbs.db_query("SELECT count(distinct(visitor_id)) 
                                  FROM stats.pageviews 
                                 WHERE user_id IS NULL 
                                   AND created_on >= now() - '30 minutes'::interval")[0]['count'].to_i
    
    online_reg = Dbs.db_query("SELECT count(*) 
                                  FROM users 
                                 WHERE lastseen_on >= now() - '30 minutes'::interval")[0]['count'].to_i
    
    User.db_query("UPDATE global_vars SET online_anonymous = #{online_anon}, online_registered = #{online_reg}")
  end
  
  def self.register_referer(user_id, remote_ip, referer)
    referer ||= ''
    # TODO HACK
    if User.db_query("SELECT * FROM refered_hits WHERE ipaddr = '#{remote_ip}' AND created_on > now() - '10 minutes'::interval").length == 0
      User.db_query("INSERT INTO refered_hits(user_id, ipaddr, referer) VALUES(#{user_id}, '#{remote_ip}', #{User.connection.quote(referer)})")
      User.db_query("UPDATE users set cache_faith_points = COALESCE(cache_faith_points + #{Faith::FPS_ACTIONS['hit']}, 0) where id = #{user_id}")
      # TODO chequear que las visitas referidas de nuestros propios dominios ni de bots cuenten
    end
  end
  
  def self.pageloadtime(request, seconds, response, controller_name, action_name, portal)
    dbs = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.get_stats
    db_queries = dbs[:queries]
    db_rows = dbs[:rows]
    response_status = response.headers['Status'] ? response.headers['Status'].split(' ')[0]: '500'
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
      puts "ya hay stats para #{tstart}, no recalculo"
      return
    end
    pageviews_by_ad_id = {}
    myre = /"([0-9]+)"/
    
    date_sql = "created_on BETWEEN '#{tstart.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{tend.strftime('%Y-%m-%d %H:%M:%S')}'"
    
    Dbs.db_query("select count(*), ads_shown from stats.pageviews where #{date_sql} AND ads_shown IS NOT NULL group by ads_shown order by ads_shown").each do |dbr|     
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
                 GROUP BY portal_id,
                          content_type_id").each do |dbr|
      statz[dbr['portal_id'].to_i]  ||= 0
      statz[dbr['portal_id'].to_i] += dbr['count'].to_i * Karma::KPS_CREATE[ContentType.find(dbr['content_type_id'].to_i).name]
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
    
    #res.keys.each do |k|
    # res2[k] = (res[k]/tot) * 100
    #end
    res2
  end
  
  def self.user_comments_by_rating(u)
    res = {}
    User.db_query("SELECT count(*)*sum(weight) as count,
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
