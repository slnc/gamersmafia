# -*- encoding : utf-8 -*-
class CompetitionsParticipantsType < ActiveRecord::Base
  has_many :competitions
end
