cur = Time.local(2001, 11, 27)
now = Time.now

while cur < now
  User.db_query("INSERT INTO stats.dates VALUES('#{cur.strftime('%Y-%m-%d')}')")
  cur = cur.advance(:days => 1)
end
