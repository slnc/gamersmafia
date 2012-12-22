# -*- encoding : utf-8 -*-
class OutstandingClan < OutstandingEntity
  def clan
    @_entity ||= Clan.find(self.entity_id)
  end

  def name
    clan.name
  end

  def logo
    clan.logo
  end

  def entity
    clan
  end
end
