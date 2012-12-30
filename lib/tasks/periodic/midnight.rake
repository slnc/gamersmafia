namespace :gm do
  desc "Midnight operations"
  task :midnight => :environment do
    Faction.delay.update_factions_cohesion
    Bet.generate_top_bets_winners_minicolumns
    User.update_remaining_ratings
    Stats::Factions.update_factions_stats # Order is important
    Stats.update_general_stats
  end
end
