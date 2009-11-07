uzers = {}
User.db_query("SELECT id, login FROM users").each do |dbu|
    uzers[dbu['login']] ||= []
    uzers[dbu['login']]<< ['User', dbu['id'].to_i]
end

UserLoginChange.db_query("SELECT user_id, old_login FROM user_login_changes").each do |dbu| 
    uzers[dbu['old_login']] ||= []
    uzers[dbu['old_login']]<< ['User', dbu['user_id'].to_i]
end

puts Time.now
i = 0
Comment.find_each(:conditions => 'deleted = \'f\'') do |c|
  c.ne_references(uzers)
  i += 1
  puts "--------------- #{i} ------------" if i % 1000 == 0
end

