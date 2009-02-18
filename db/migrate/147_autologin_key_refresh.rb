class AutologinKeyRefresh < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table autologin_keys add column lastused_on timestamp not null default now();"
    execute "update autologin_keys set lastused_on = (select lastseen_on from users where id = autologin_keys.user_id);"
    slonik_execute "create index autologin_keys_lastused_on on autologin_keys(lastused_on);"
    execute "delete from autologin_keys where lastused_on < now() - '3 months'::interval;"
    
    # borramos todas excepto la última usada
    # delete from autologin_keys parent where id not in (select id from autologin_keys child where parent.user_id = child.user_id )
    User.db_query("select count(*), user_id from autologin_keys group by user_id HAVING count(*) > 3 order by count(*) desc").each do |dbr|
      uid = dbr['user_id']
      User.db_query("DELETE FROM autologin_keys where user_id = #{uid} AND id NOT IN (select id from autologin_keys where user_id = #{uid} order by id desc limit 3)")
    end
  end

  def self.down
  end
end
