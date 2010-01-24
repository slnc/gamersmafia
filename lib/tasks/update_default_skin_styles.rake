namespace :gm do
  desc "Update CSS files of default skins"
  task :update_default_skin_styles => :environment do
    Rake::Task["gm:update_games_and_factions_sprite"].invoke
    FactionsSkin.find(:all).each do |s| GmSys.job("Skin.find(#{s.kid}).save_config && Skin.find(#{s.kid}).gen_compressed") end
    Skin.find_by_hid('default').gen_compressed
  end
end
