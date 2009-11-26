namespace :gm do
  desc "Update CSS files of default skins"
  task :update_default_skin_styles => :environment do
    Rake::Task["gm:update_games_and_factions_sprite"].invoke
    FactionsSkin.find(:all).each do |s| s.save_config end
    Skin.find_by_hid('default').gen_compressed
    Skin.find_by_hid('arena').gen_compressed
    Skin.find_by_hid('bazar').gen_compressed
  end
end
