module Factions
  def self.user_joins_faction(user, new_faction_id)
    return if user.faction_id == new_faction_id
    new_faction_id = new_faction_id.id if new_faction_id.kind_of?(Faction)
    
    if user.faction_id then
      Faction.decrement_counter('members_count', user.faction_id)
      CacheObserver.expire_fragment("/common/facciones/#{user.faction_id}/last_joined") # TODO UGLY!
      CacheObserver.expire_fragment("/common/facciones/miembros/#{user.faction_id}/page_*") # TODO UGLY
      CacheObserver.expire_fragment "/common/facciones/#{Time.now.strftime('%Y%m%d')}/stats/#{user.faction_id}"
      graph_prev = "#{Rails.root}/public/cache/graphs/faction_users_ratios/#{Time.now.strftime('%Y%m%d')}/#{user.faction_id}.png"
      File.unlink(graph_prev) if File.exists?(graph_prev)
    end
    
    user.faction_id = new_faction_id
    user.faction_last_changed_on = Time.now
    
    if user.save and user.faction_id then
      Faction.increment_counter('members_count', user.faction_id)
    end
    
    CacheObserver.expire_fragment('/common/home/index/factions_stats') # TODO hack
    CacheObserver.expire_fragment('/common/facciones/list_*') # TODO UGLY!
    if user.faction_id
      CacheObserver.expire_fragment("/common/facciones/#{user.faction_id}/last_joined") # TODO UGLY!
      CacheObserver.expire_fragment("/common/facciones/miembros/#{user.faction_id}/page_*") # TODO UGLY
      CacheObserver.expire_fragment "/common/facciones/#{Time.now.strftime('%Y%m%d')}/stats/#{user.faction_id}"
      graph_next = "#{Rails.root}/public/cache/graphs/faction_users_ratios/#{Time.now.strftime('%Y%m%d')}/#{user.faction_id}.png"
      File.unlink(graph_next) if File.exists?(graph_next)
    end
  end
  
  def self.default_faction_for_user(u)
    if u.nil?
      nil
    else # user logged in
      if u.faction_id
        Faction.find(u.faction_id)
      else
        nil
      end
    end
  end
end