namespace :gm do
  desc "Weekly operations"
  task :weekly => :environment do
        require 'app/controllers/application'
    # Eliminamos cache de páginas de comentarios (limpiando avatares y stats)
    `find #{FRAGMENT_CACHE_PATH}/comments -mindepth 1 -mmin +10080 -type d -exec rm -r {} \\; &> /dev/null` if File.exists?("#{FRAGMENT_CACHE_PATH}/comments")
    pay_factions_wages
    update_content_ranks
    send_weekly_page_render_report_and_truncate
    Emblems.give_emblems
    Reports.send_mrachmed_dominical
  end
  
  def pay_factions_wages
    # para cada facción con boss
    User.db_query("select (select code from portals where id = stats.portals.portal_id) as code, sum(karma)
  from stats.portals
 where portal_id in (select id
                       from portals
                      where code in (select code
                                       from games UNION
                                     select code from platforms))
   and created_on >= now() - '7 days'::interval
 group by portal_id
having portal_id in (select id
                       from portals
                      where code in (select code
                                       from factions
                                      where created_on < now() - '7 days'::interval
                                        and id IN #{Faction.factions_ids_with_bigbosses}))
             AND sum(karma) > 0").each do |dbr|
      f = Faction.find_by_code(dbr['code'])
      next unless f
      
      if f.boss && f.underboss
        ammount_boss = 0.05 * 0.6 * dbr['sum'].to_i
        ammount_underboss = 0.05 * 0.4 * dbr['sum'].to_i
      elsif f.underboss
        ammount_underboss = 0.05 * 1.0 * dbr['sum'].to_i
        ammount_boss = nil
      elsif f.boss
        ammount_boss = 0.05 * 1.0 * dbr['sum'].to_i
        ammount_underboss = nil
else next
      end
      # puts "#{f.code} #{ammount_boss} #{ammount_underboss}"
      # TODO tests de esto
      Bank.transfer(:bank, f.boss, ammount_boss, "Sueldo de boss de la facción #{f.name}")
      Bank.transfer(:bank, f.underboss, ammount_underboss, "Sueldo de underboss de la facción #{f.name}") if ammount_underboss
    end
  end
  
  def update_content_ranks
    processed_root_cats = []
    processed_ctypes = []
    ContentRating.find(:all, :conditions => "date_trunc('day', created_on) = date_trunc('day', now() - '8 days'::interval)").each do |cr|
      rc = cr.content.real_content
      if Cms::CONTENTS_WITH_CATEGORIES.include?(rc.class.name) then
        root_cat = rc.main_category.root
        proc_root_cat_id = "#{Inflector::tableize(rc.class.name)}#{root_cat.id}"
        next if processed_root_cats.include?(proc_root_cat_id)
        cat_ids = root_cat.all_children_ids
        q = "WHERE #{Inflector::tableize(rc.class.name)}_category_id IN (#{cat_ids.join(',')})"
        processed_root_cats<< proc_root_cat_id
      else
        next if processed_ctypes.include?(rc.class.name)
        q = ''
      end
      User.db_query("UPDATE #{Inflector::tableize(rc.class.name)} SET cache_weighted_rank = null #{q}")
    end
    
    ContentType.find(:all).each do |ctype|
      #  slonik_execute "alter table #{Inflector::tableize(ctype.name)} add column cache_weighted_rank numeric(10, 2);"
      # puts ctype.name
      Object.const_get(ctype.name).find(:all, :conditions => "cache_weighted_rank is null and state = #{Cms::PUBLISHED}").each do |content|
        content.clear_rating_cache
        nil
      end
    end
  end
  
  def send_weekly_page_render_report_and_truncate
    # TODO
    # TODO User.db_query("DELETE FROM stats.pageloadtime WHERE created_on <= now() - '1 week'::interval")
    @top_avg_time = User.db_query("SELECT avg(time), 
                          stddev(time), 
                          count(*), 
                          controller, 
                          action 
                     FROM stats.pageloadtime 
                    WHERE created_on >= now() - '1 week'::interval 
                 GROUP BY controller, action
                 HAVING count(*) > 10
                 ORDER BY avg(time) DESC")
                 
    @top_count = User.db_query("SELECT avg(time), 
                          stddev(time), 
                          count(*), 
                          controller, 
                          action 
                     FROM stats.pageloadtime 
                    WHERE created_on >= now() - '1 week'::interval 
                 GROUP BY controller, action
                 HAVING count(*) > 10
                 ORDER BY count(*) DESC")
    Notification.deliver_weekly_avg_page_render_time(:top_avg_time => @top_avg_time, :top_count => @top_count)
    
    User.db_query("DELETE FROM stats.pageloadtime WHERE created_on <= now() - '1 week'::interval")
  end
end
