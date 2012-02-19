class OutstandingEntity < ActiveRecord::Base
  validates_presence_of :active_on
  validates_uniqueness_of :active_on, :scope => [:type, :portal_id]

  def portal
    portal_id == -1 ? GmPortal.new : Portal.find(self.portal_id)
  end

  def self.factory(portal_id, entity_cls, entity_id, reason)
    # El algoritmo de encolado funciona de la siguiente forma:
    # Se calcula el número de usuarios que están usando el servicio. El usuario actual puede aparecer como muy pronto cada "numero de usuarios usando el servicio" días
    # El número de usuarios usando el servicio se calcula en base a las dos últimas semanas.

    q_portal = "= #{portal_id}"
    r_portal = portal_id


    users_using = User.db_query("SELECT count(distinct(entity_id))
                                      FROM outstanding_entities
                                     WHERE type = '#{entity_cls}'
                                       AND portal_id #{q_portal}
                                       AND active_on > now() - '2 weeks'::interval")[0]['count'].to_i

    # buscamos última vez publiqué
    last_mine = OutstandingEntity.find(:first, :conditions => ["entity_id = ? AND portal_id #{q_portal}", entity_id], :order => 'active_on desc')
    tstamp_last = last_mine ? last_mine.active_on : Time.at(0)

    min_tstamp = Time.at(tstamp_last.to_time.to_i + users_using * 86400) # Si el usuario ya lo está usando no podrá aparecer 2 días seguidos
    # Le buscamos el hueco donde publicar
    cur = 1.day.since
    found = false
    while !found
      if OutstandingEntity.find(:first, :conditions => ["type = ? AND portal_id #{q_portal} AND active_on = ?", entity_cls, cur], :order => 'active_on desc').nil? && cur >= min_tstamp
        found = true
        oe = Object.const_get(entity_cls).create({:entity_id => entity_id, :active_on => cur, :portal_id => r_portal, :reason => reason})
      else
        cur = cur.advance(:days => 1)
      end
    end
    # portal_name = r_portal ? Portal.find(r_portal).name : 'gamersmafia.com'
    oe
  end
end