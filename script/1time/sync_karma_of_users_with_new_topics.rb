i = 0
User.find(:all, :conditions => 'id in (select distinct(user_id) from topics where created_on > \'2007-01-23 00:00:00\')').each do |u|
  u.cache_karma_points = nil
  User.db_query("UPDATE users SET cache_karma_points = null WHERE id = #{u.id}")
  u.karma_points
  i += 1
end