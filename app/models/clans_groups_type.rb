# -*- encoding : utf-8 -*-
class ClansGroupsType < ActiveRecord::Base
  has_many :clans_groups
  CLANLEADERS = 1
  MEMBERS = 2
end
