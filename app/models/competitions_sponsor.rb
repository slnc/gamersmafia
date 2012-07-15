# -*- encoding : utf-8 -*-
class CompetitionsSponsor < ActiveRecord::Base
  belongs_to :competition

  file_column :image

  validates_presence_of :competition_id

  plain_text :name
end
