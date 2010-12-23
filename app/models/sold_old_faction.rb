class SoldOldFaction < SoldProduct
  def _use(options)
    f = Faction.find(:first, :conditions => ['id = ?', options[:faction_id]])
    if f.nil?
      self.errors.add('faction_id', 'la facción especificada no existe')
      return false
    end
    
    if !f.is_orphan?
      self.errors.add('faction_id', 'la facción especificada ya no es huérfana')
      return false
    end 
    
    fold = Faction.find_by_boss(user)
    fold.update_boss(nil) if fold
    fold = Faction.find_by_underboss(user)
    fold.update_underboss(nil) if fold
    
    if f.update_boss(user)
      Factions::user_joins_faction(self.user, f.id) unless self.user.faction_id == f.id 
      SlogEntry.create({:type_id => SlogEntry::TYPES[:info], :headline => "Facción huérfana comprada <strong><a href=\"#{Routing.gmurl(f)}\">#{f.name}</a></strong> por <a href=\"#{Routing.gmurl(f.boss)}\">#{f.boss.login}</a>"})
      true
    else
      f.errors.each do |err|
        self.errors.add(*err)
      end
      false
    end
  end
end
