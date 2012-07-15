# -*- encoding : utf-8 -*-
class SoldClanWebsite < SoldProduct
  def _use(options)
    clan = Clan.find(options[:clan_id])
    raise AccessDenied unless clan.user_is_member(self.user_id) && !clan.website_activated
    clan.activate_website
    true
  end
end
