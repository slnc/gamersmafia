Faction.find(:all).each do |f|
  f.members_count = f.users.count
  f.save
end