class Product < ActiveRecord::Base
  has_many :sold_products
  
  public
  def can_be_bought_by_user(u)
    send "can_be_bought_by_user_#{ActiveSupport::Inflector::underscore(self.cls)}".to_sym, u
  end
  
  def cant_be_bought_by_user_reason(u)
    send "cant_be_bought_by_user_reason_#{ActiveSupport::Inflector::underscore(self.cls)}".to_sym, u
  end
  
  # TODO refactorize
  private
  def can_be_bought_by_user_sold_profile_signatures(u)
   (not u.enable_profile_signatures?)
  end
  
  def can_be_bought_by_user_sold_comments_sig(u)
   (not u.enable_comments_sig?)
  end
  
  def can_be_bought_by_user_sold_faction_avatar(u)
    Faction.find_by_boss(u) || Faction.find_by_underboss(u)
  end
  
  def can_be_bought_by_user_sold_faction(u)
    br = BanRequest.count(:conditions => ['banned_user_id = ? AND confirmed_on >= now() - \'3 months\'::interval AND unban_confirmed_on >= now() - \'3 months\'::interval', u.id]) == 0
    fb = u.sold_products.factions.recent.count == 0
    
    br && fb
  end
  
  def can_be_bought_by_user_sold_old_faction(u)
    can_be_bought_by_user_sold_faction(u) && Faction.count_orphaned > 0
  end
  
  def can_be_bought_by_user_sold_change_nick(u)
    true
  end
  
  def can_be_bought_by_user_sold_outstanding_user(u)
    true
  end
  
  def can_be_bought_by_user_sold_gmtv_channel(u)
    true
  end
  
  def can_be_bought_by_user_sold_user_avatar(u)
    true
  end
  
  def can_be_bought_by_user_sold_clan_website(u)
    return false if u.clans_ids.size == 0
    u.clans.each do |clan|
      return true if clan.user_is_clanleader(u.id) && !clan.website_activated
    end
    false
  end
  
  def can_be_bought_by_user_sold_clan_avatar(u)
    u.clans_ids.size > 0
  end
  
  def can_be_bought_by_user_sold_outstanding_clan(u)
    u.clans_ids.size > 0
  end
  
  def cant_be_bought_by_user_reason_sold_comments_sig(u)
    "ya lo tienes."
  end
  
  def cant_be_bought_by_user_reason_sold_profile_signatures(u)
    "ya lo tienes."
  end
  
  def cant_be_bought_by_user_reason_sold_clan_avatar(u)
      "debes pertenecer a al menos un clan"      
  end
  
  def cant_be_bought_by_user_reason_sold_outstanding_clan(u)
      "debes pertenecer a al menos un clan"
  end
  
  def cant_be_bought_by_user_reason_sold_faction(u)
    "tu historial delictivo durante los últimos 6 meses debe estar impecable"
  end
  
  def cant_be_bought_by_user_reason_sold_faction_avatar(u)
    "no eres boss ni underboss de ninguna facción"
  end
  
  def cant_be_bought_by_user_reason_sold_old_faction(u)
    if Faction.count_orphaned == 0 
      "no hay ninguna facción huérfana"
    else
      cant_be_bought_by_user_reason_sold_faction(u)
    end
  end
  
  def cant_be_bought_by_user_reason_sold_clan_website(u)
    if u.clans_ids.size == 0
      "debes pertenecer a al menos un clan"
    else
      "solo el clanleader de un clan puede comprar la web y no se puede comprar más de una web para el mismo clan"
    end
  end
end
