# -*- encoding : utf-8 -*-
class SoldFaction < SoldProduct
  def _use(options)
    raise 'faction type unset' unless options[:type]
    cls = options[:type] == 'game' ? Game : GamingPlatform
    options[:code].downcase!
    if (Game.count(:conditions => ['code = ?', options[:code]]) > 0) ||
        (GamingPlatform.count(:conditions => ['code = ?', options[:code]]) > 0)
      return false
    end

    thing = cls.new(options.pass_sym(:code, :name))
    if thing.save
      fold = Faction.find_by_boss(user)
      fold.update_boss(nil) if fold
      fold = Faction.find_by_underboss(user)
      fold.update_underboss(nil) if fold
      f = thing.faction
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
      msg = []
      thing.errors.each do |err|
        msg.append(err)
      end
      self.errors[:base] << msg.join("\n")
      false
    end
  end
end
