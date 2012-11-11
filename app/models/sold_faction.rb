# -*- encoding : utf-8 -*-
class SoldFaction < SoldProduct
  def _use(options)
    raise 'Game unset' unless options[:game_id]
    cls = Game
    game = Game.find(options[:game_id])
    raise "Juego '#{game.name}' ya tiene facción" if game.has_faction?

    game.create_contents_categories
    fold = Faction.find_by_boss(user)
    fold.update_boss(nil) if fold
    fold = Faction.find_by_underboss(user)
    fold.update_underboss(nil) if fold
    f = game.faction
    if f.update_boss(user)
      Factions::user_joins_faction(self.user, f.id)
      true
    else
      f.errors.each do |err|
        self.errors.add(*err)
      end
    end
  end
end
