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
  
  def self.current(portal_id, redir=true)
    bought = OutstandingClan.find(:first, :conditions => ["portal_id = ? AND active_on = ? ", portal_id, Time.now])
    i = 0
    while bought.nil? && i < 7 # se lo regalamos al que más karma haya generado en los últimos 3 días en toda la red y no haya sido elegido ayer
      # TODO cambiar la query para regalárselo al clan que más karma genere
      # TODO
      # raise "TODO hacer como en comunidad.html para sacar las visitas"
      return nil
      cool_clanz = User.db_query("select (select clan_id from portals where id = stats.portals.portal_id) 
                                                       from stats.portals 
                                                      where created_on >= now() - '14 days'::interval 
                                                        and portal_id in (select id 
                                                                            from portals 
                                                                           where clan_id is not null) 
                                                   GROUP BY portal_id 
                                                     HAVING sum(karma) > 0 
                                                   order by sum(karma) desc 
                                                      limit 1")
      
      # TODO tests
      if cool_clans.size > 0 then
        bu = Clan.find(cool_clanz['clan_id'].to_i)
        bought = OutstandingClan.create(:portal_id => portal_id, :active_on => Time.now, :entity_id => bu.id, :reason => "<strong>#{cool_guys[0]['sum']}</strong> visitas en la última semana")
        if bought.new_record? && redir # si no se ha podido guardar probablemente sea porque se ha generado una nueva entrada a la vez
          bought = self.current(portal_id, false)
        elsif bought.new_record?
          bought = nil
        end
      else
        i += 1
      end      
    end
    bought
  end
end