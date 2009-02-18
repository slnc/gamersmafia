class CompetitionsMatchesReport < ActiveRecord::Base
  belongs_to :competitions_match
  belongs_to :user
end
