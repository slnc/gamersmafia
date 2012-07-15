# -*- encoding : utf-8 -*-
class UsersAction < ActiveRecord::Base
  belongs_to :user
  has_many :users_newsfeeds, :dependent => :destroy

  NEW_RECRUITMENT_AD = 0
  PROFILE_PHOTO_UPDATED = 1
  USER_CHANGED_TO_NEW_FACTION = 2
  NEW_CLANS_MOVEMENT = 3
  NEW_CLAN = 4
  NEW_CONTENT = 5
  NEW_PROFILE_SIGNATURE_SIGNED = 6
  NEW_PROFILE_SIGNATURE_RECEIVED = 7
  NEW_FRIENDSHIP_SENDER = 8
  NEW_FRIENDSHIP_RECEIVER = 9
  NEW_USERS_EMBLEM = 10

  validates_presence_of :type_id, :user_id

end
