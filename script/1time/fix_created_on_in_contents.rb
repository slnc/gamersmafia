i = 0
Content.find(:all, :conditions => "date_trunc('day', created_on) = '2007-01-21 00:00:00' AND state = 2").each do |c|
  User.db_query("UPDATE contents SET created_on = '#{c.real_content.created_on.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{c.id}")
  if i % 100 == 0
    sleep 0.5
    puts i
  end
  i += 1
end
