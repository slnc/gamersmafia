namespace :gm do
  desc "Weekly report for faction leaders"
  task :weekly_report => :environment do
    nagato = User.find_by_login!(:nagato)
    Faction.find_unorphaned.each do |f|
      NotificationEmail.faction_summary(
          f.boss, :sender => nagato, :faction => f).deliver if f.boss
      NotificationEmail.faction_summary(
          f.underboss, :sender => nagato, :faction => f).deliver if f.underboss
    end
  end
end
