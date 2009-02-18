class Oz < ActiveRecord::Base; end

Oz.establish_connection( :adapter  => 'postgresql',
                         :host     => 'localhost',
                         :username => 'postgres',
                         :password => 'ic4ro69',
                         :database => 'gm_ozone2'
                        )
i = 0

parsed_users = []

Oz.db_query("SELECT id, username FROM users ORDER BY id asc").each do |dbu|
  next if parsed_users.include? dbu['id']
  u = User.find_by_id(dbu['id'])
  if u.nil?
    puts "#{dbu['username']} (#{dbu['id']}) not found in GM3 db, skipping.."
  else
    dbreg = Oz.db_query("select min(timestamp) from actions where user_id = #{u.id} and type_id = 8")[0]
    dblast = Oz.db_query("select max(timestamp) from actions where user_id = #{u.id} and type_id = 7")[0]
    qreg = false
    qlast = false
    if dbreg['min'].to_s != ''
      prevreg = u.created_on
      User.db_query("UPDATE users SET created_on = '#{dbreg['min']}'::timestamp WHERE id = #{u.id} AND created_on > '#{dbreg['min']}'::timestamp") 
      u.reload
      qreg = true if u.created_on != prevreg
    end
    if dblast['max'].to_s != ''
      prevlast = u.lastseen_on
      User.db_query("UPDATE users SET lastseen_on = '#{dblast['max']}'::timestamp WHERE id = #{u.id} AND lastseen_on < '#{dblast['max']}'::timestamp" )
      u.reload
      qlast = true if u.lastseen_on != prevlast
    end
    i +=1 if qreg or qlast
  end
  parsed_users<< dbu['id']
end

puts "#{i} usuarios modificados"
