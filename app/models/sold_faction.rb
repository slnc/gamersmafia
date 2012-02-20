class SoldFaction < SoldProduct
  def _use(options)
    raise 'faction type unset' unless options[:type]
    cls = options[:type] == 'game' ? Game : Platform
    options[:code].downcase!
    return false if (Game.count(:conditions => ['code = ?', options[:code]]) > 0) || (Platform.count(:conditions => ['code = ?', options[:code]]) > 0)

    thing = cls.new(options.pass_sym(:code, :name))
    if thing.save
      fold = Faction.find_by_boss(user)
      fold.update_boss(nil) if fold
      fold = Faction.find_by_underboss(user)
      fold.update_underboss(nil) if fold
      f = thing.faction
      # puts '---------'
      # puts thing
      # puts f
      if f.update_boss(user)
        Factions::user_joins_faction(self.user, f.id)
        true
      else
        f.errors.each do |err|
          self.errors.add(*err)
        end
        thing.destroy
      end
    else
      thing.errors.each do |err|
        self.errors.add(*err)
      end
      false
    end
  end
end
