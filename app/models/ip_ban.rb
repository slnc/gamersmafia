# -*- encoding : utf-8 -*-
class IpBan < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id
  scope :active, :conditions => "expires_on IS NULL or expires_on >= now()"
end
