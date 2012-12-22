namespace :gm do
  desc "Update sprite of games and factions"
  task :update_entity_favicons => :environment do
    Skins.update_entity_favicons
  end
end
