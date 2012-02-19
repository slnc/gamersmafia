class OutstandingUser < OutstandingEntity
  def user
    @_entity ||= User.find(self.entity_id)
  end

  def name
    user.login
  end

  def entity
    user
  end

  def logo
    user.show_avatar
  end

  def self.current(portal_id, redir=true)
    bought = OutstandingUser.find(:first, :conditions => ["portal_id = ? AND active_on = ? ", portal_id, Time.now])
    i = 0 # lo vamos a intentar 3 veces
    while bought.nil? && i < 3 # se lo regalamos al que más karma haya generado en los últimos 3 días en toda la red y no haya sido elegido ayer
      cool_guys = User.db_query("SELECT user_id, sum(karma) as sum
                                                      FROM stats.users_karma_daily_by_portal
                                                     WHERE created_on >= now() - '7 days'::interval
                                                       AND portal_id = #{portal_id}
                                                       AND user_id NOT IN (SELECT entity_id
                                                                             FROM outstanding_entities
                                                                            WHERE type = 'OutstandingUser'
                                                                              AND active_on >= now() - '3 days'::interval)
                                                       AND user_id IN (SELECT id FROM users WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')}))
                                                  GROUP BY user_id
                                                  ORDER BY sum(karma) DESC LIMIT 1")

      # TODO añadir más razones para ser premiado
      # TODO tests
      if cool_guys.size > 0 then
        bu = User.find(cool_guys[0]['user_id'].to_i)
        bought = OutstandingUser.create(:portal_id => portal_id, :active_on => Time.now, :entity_id => bu.id, :reason => "<strong>#{cool_guys[0]['sum']}</strong> puntos de karma en 3 días")
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
