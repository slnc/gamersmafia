# script sincronización inicial de karma
for u in User.find(:all, :conditions => 'confirmed=1 and cache_karma_points > 0', :order => 'id asc')
  u.cash = Bank::convert(u.cache_karma_points, 'karma_points')
  u.save
  CashMovement.create({:user_id_to => u.id, :ammount => u.cash, :description => 'Karma generado hasta 22/Jun/2006'})
end

