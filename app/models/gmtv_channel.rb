# -*- encoding : utf-8 -*-
class GmtvChannel < ActiveRecord::Base
  file_column :file
  file_column :screenshot
  belongs_to :faction
  belongs_to :user
end
