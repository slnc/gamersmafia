namespace :gm do
  desc "Update sprite of games and factions"
  task :update_portal_favicons => :environment do
    Skins.update_portal_favicons
  end
end
