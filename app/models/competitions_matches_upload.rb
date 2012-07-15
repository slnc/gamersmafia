# -*- encoding : utf-8 -*-
class CompetitionsMatchesUpload < ActiveRecord::Base
  belongs_to :user
  belongs_to :competitions_match

  file_column :file

#  validates_presence_of :file
  validates_presence_of :competitions_match
  validates_presence_of :user
end
