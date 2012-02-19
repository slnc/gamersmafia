namespace :gm do
  desc "Update CSS files of default skins"
  task :update_default_skin_styles => :environment do
    Rake::Task["gm:update_games_and_factions_sprite"].invoke
    Skins.update_default_skin_styles
  end
end
