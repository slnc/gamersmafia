# -*- encoding : utf-8 -*-
module ClanesHelper
  def get_biggest_clans
    Clan.active.find(:all,
                     :conditions => "members_count > 0",
                     :order => "members_count DESC",
                     :limit => 10)
  end

  def get_newest_clans
    Clan.active.find(:all,
                     :order => "created_on DESC",
                     :limit => 5)
  end
end
