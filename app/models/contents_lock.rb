# -*- encoding : utf-8 -*-
class ContentsLock < ActiveRecord::Base
  validates_uniqueness_of :content_id
  validates_presence_of :user_id
  validates_presence_of :content_id

  belongs_to :user
end
