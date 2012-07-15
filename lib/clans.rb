# -*- encoding : utf-8 -*-
module Clans
  module Authentication
    # Authentication module to be mixed in with a Controller.
    attr_accessor :clan

    def require_auth_clan_leader
      c = Clan.find(@user.last_clan_id)
      raise AccessDenied unless c.deleted == false && c.user_is_clanleader(@user.id)
    end

    def require_auth_member
      c = Clan.find(@user.last_clan_id)
      raise AccessDenied unless c.deleted == false && c.user_is_member(@user.id)
    end
  end
end
