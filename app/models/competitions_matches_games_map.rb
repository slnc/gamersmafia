class CompetitionsMatchesGamesMap < ActiveRecord::Base
  belongs_to :competitions_match
  belongs_to :games_map
end
