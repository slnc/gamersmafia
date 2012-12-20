# -*- encoding : utf-8 -*-
module ClanesHelper
  # Returns top 10 clans by size given a portal.
  def get_biggest_clans(portal)
    get_portal_clans(portal,
                     :conditions => "members_count > 0",
                     :order => "members_count DESC",
                     :limit => 10)
  end

  def get_newest_clans(portal)
    get_portal_clans(portal,
                     :order => "created_on DESC",
                     :limit => 5)
  end

  def get_portal_clans(conditions, options)
    Clan.active.find(:all, options)
  end
end
