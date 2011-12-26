require 'RMagick'

namespace :gm do
  desc "Update sprite of games and factions"
  task :update_games_and_factions_sprite => :environment do
    Skins.update_games_and_factions_sprite
  end
end
