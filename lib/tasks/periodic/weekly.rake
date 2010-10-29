namespace :gm do
  desc "Weekly operations"
  task :weekly => :environment do
    require 'app/controllers/application_controller'
    # Eliminamos cache de páginas de comentarios (limpiando avatares y stats)
    `find #{FRAGMENT_CACHE_PATH}/comments -mindepth 1 -mmin +10080 -type d -exec rm -r {} \\; &> /dev/null` if File.exists?("#{FRAGMENT_CACHE_PATH}/comments")
    pay_organizations_wages
    Emblems.give_emblems
    Reports.send_mrachmed_dominical
    #Download.check_invalid_downloads
    send_weekly_page_render_report_and_truncate
    recalculate_terms_count
    User.db_query("DELETE FROM ip_passwords_resets_requests WHERE created_on <= now() - '1 week'::interval;")
    update_default_comments_valorations_weight
    update_content_ranks
  end
  
  def update_default_comments_valorations_weight
    User.find(:all, :conditions => 'lastseen_on >= now() - \'1 week\'::interval and cache_karma_points > 0').each do |u|
      prev = u.default_comments_valorations_weight
      u.update_default_comments_valorations_weight
      if prev != u.default_comments_valorations_weight
        u.comments_valorations.recent.find(:all, :include => :comment).each do |cv|
          cv.update_attributes(:weight => Comments.get_user_weight_in_comment(u, cv.comment))
        end
      end
    end
  end
  
  def recalculate_terms_count
    # TODO hack
    Term.find_each do |t| t.recalculate_contents_count end
  end
  
  def pay_organizations_wages
    User.db_query("select (select code from portals where id = stats.portals.portal_id) as code, 
                          sum(karma)
  from stats.portals
 where portal_id in (select id
                       from portals
                      where code in (select code from games 
                                     UNION
                                     select code from platforms
                                     UNION
                                     select code from bazar_districts))
   and created_on >= now() - '7 days'::interval
 group by portal_id
having portal_id in (select id
                       from portals
                      where code in (select code
                                       from factions
                                      where created_on < now() - '7 days'::interval
                                        and id IN #{Faction.factions_ids_with_bigbosses} 
                                UNION
                                     select code
                                       from bazar_districts)
                                     
                                     )
             AND sum(karma) > 0").each do |dbr|
      t = Term.single_toplevel(:slug => dbr['code'])
      if t.bazar_district_id
        master = :don
        undermaster = :mano_derecha
        organization = t.bazar_district
      elsif t.game_id || t.platform_id
        master = :boss
        undermaster = :underboss
        organization = Faction.find_by_code(t.game_id ? t.game.code : t.platform.code) 
      end
      if organization.nil?
        puts "ERROR: cannot find associated organization for portal_code #{dbr['code']}"
        next
      end
      
      master_o = organization.send(master)
      undermaster_o = organization.send(undermaster)
      next if master_o.nil? && undermaster_o.nil?
      
      if master_o && undermaster_o
        ammount_boss = 0.05 * 0.6 * dbr['sum'].to_i
        ammount_underboss = 0.05 * 0.4 * dbr['sum'].to_i
      elsif undermaster_o
        ammount_underboss = 0.05 * 1.0 * dbr['sum'].to_i
        ammount_boss = nil
      elsif master_o
        ammount_boss = 0.05 * 1.0 * dbr['sum'].to_i
        ammount_underboss = nil
      end
      
      Bank.transfer(:bank, master_o, ammount_boss, "Sueldo de #{master} de #{organization.name}") if ammount_boss
      Bank.transfer(:bank, undermaster_o, ammount_underboss, "Sueldo de #{undermaster} de #{organization.name}") if ammount_underboss
    end
  end
  
  def update_content_ranks
    processed_root_cats = []
    processed_ctypes = []
    ContentRating.find(:all, :conditions => "date_trunc('day', created_on) = date_trunc('day', now() - '8 days'::interval)").each do |cr|
      rc = cr.content.real_content
      if Cms::CONTENTS_WITH_CATEGORIES.include?(rc.class.name) then
        root_cat = rc.main_category.root
        proc_root_cat_id = "#{ActiveSupport::Inflector::tableize(rc.class.name)}#{root_cat.id}"
        next if processed_root_cats.include?(proc_root_cat_id)
        cat_ids = root_cat.all_children_ids
        #q = "WHERE #{ActiveSupport::Inflector::tableize(rc.class.name)}_category_id IN (#{cat_ids.join(',')})"
        q = '' # TODO BROKEN!!! 
        processed_root_cats<< proc_root_cat_id
      else
        next if processed_ctypes.include?(rc.class.name)
        q = ''
      end
      User.db_query("UPDATE #{ActiveSupport::Inflector::tableize(rc.class.name)} SET cache_weighted_rank = null #{q}")
    end
    return # TODO deshabilitado recálculo de contenidos más votados porque este algoritmo no es escalable.
    ContentType.find(:all).each do |ctype|
      #  slonik_execute "alter table #{ActiveSupport::Inflector::tableize(ctype.name)} add column cache_weighted_rank numeric(10, 2);"
      # puts ctype.name
      Object.const_get(ctype.name).find_each(:conditions => "cache_weighted_rank is null and state = #{Cms::PUBLISHED}") do |content|
        next if content.respond_to?(:clan_id) && content.clan_id
        begin
          content.clear_rating_cache
        rescue Exception => e
          puts "Error with #{content.id}(#{ctype}): #{e}"
        end
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
