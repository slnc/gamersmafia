# -*- encoding : utf-8 -*-
class ContentsVersion < ActiveRecord::Base
  belongs_to :content
  serialize :data
end
