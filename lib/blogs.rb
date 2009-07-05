module Blogs
  def self.user_authority(user)
    c = user.blogentries.count(:conditions => "state = '#{Cms::PUBLISHED}'")
    if c > 0
      # TODO pensar junto a cache_weighted_rank
      rating = User.db_query("SELECT COALESCE(avg(cache_rating), 5.0) as avg FROM blogentries WHERE state = '#{Cms::PUBLISHED}' AND cache_rated_times > 0 AND user_id = #{user.id}")[0]['avg'].to_f
      c * (rating/10.0)
    else
      0
    end
  end
  
  # TODO cache
  # Si vamos a usar indicadores de popularidad usar logaritmos para suavizar las diferencias.
  def self.max_user_authority
    User.db_query("select count(*)*((select coalesce(avg(cache_rating), 5.0) from blogentries where user_id = padre.user_id and state <> '#{Cms::DELETED}' and cache_rated_times > 0) /10.0) as authority 
                     from blogentries padre 
                    where state=#{Cms::PUBLISHED} 
                 group by user_id 
                 order by authority desc limit 1")[0]['authority'].to_f
  end
  
  def self.top_bloggers(opts={})
    opts = {:limit => 5}.merge(opts)
    User.find_by_sql("SELECT a.id, a.login
                     FROM users a
                     JOIN blogentries padre on a.id = padre.user_id
                    WHERE padre.state=#{Cms::PUBLISHED} 
                 GROUP BY a.id, a.login, padre.user_id
                 ORDER BY count(*)*((SELECT coalesce(avg(cache_rating), 5.0) FROM blogentries WHERE user_id = padre.user_id and state <> '#{Cms::DELETED}' and cache_rated_times > 0) /10.0) desc limit #{opts[:limit]}")
  end
  
  def self.top_bloggers_in_date_range(date_start, date_end)
    date_start, date_end = date_end, date_start if date_start > date_end
    
    # devuelve los usuarios cuyas entradas han sido más leídas en la última semana
    User.db_query("SELECT count(distinct(visitor_id)), 
		  COALESCE((select user_id from blogentries where created_on >= now() - '1 week'::interval AND id = stats.pageviews.model_id::int4), NULL) as blogger_user_id
                     FROM stats.pageviews 
                    WHERE created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
                      AND controller = 'blogs' 
                      AND action = 'blogentry' 
                      AND model_id <> '' 
                 GROUP BY blogger_user_id 
    	           HAVING COALESCE((select user_id from blogentries where created_on >= now() - '1 week'::interval AND id = stats.pageviews.model_id::int4), NULL) IS NOT NULL
                 ORDER BY count(distinct(visitor_id)) desc limit 10").collect do |dbr|
      if dbr['blogger_user_id'].to_i > 0
        [User.find(dbr['blogger_user_id'].to_i), dbr['count'].to_i]
      else
        nil
      end
    end
  end
end
