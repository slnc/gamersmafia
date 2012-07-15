# -*- encoding : utf-8 -*-
class GamesMode < ActiveRecord::Base
  validates_presence_of :entity_type
  belongs_to :game
end
