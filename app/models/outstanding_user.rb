# -*- encoding : utf-8 -*-
class OutstandingUser < OutstandingEntity
  SQL_CANDIDATES = <<-END
SELECT user_id, SUM(karma) as sum
FROM stats.users_karma_daily_by_portal
WHERE created_on BETWEEN now() - '21 days'::interval
                     AND now() - '14 days'::interval
AND portal_id = %s
AND user_id NOT IN (
  SELECT entity_id
  FROM outstanding_entities
  WHERE type = 'OutstandingUser'
  AND active_on >= now() - '3 days'::interval)
  AND user_id IN (SELECT id FROM users WHERE state IN (%s))
GROUP BY user_id
HAVING SUM(karma) > 0
ORDER BY SUM(karma) DESC
LIMIT 1
  END

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

  def self.current(portal_id)
    bought = OutstandingUser.find(
        :first,
        :conditions => [
            "portal_id = ? AND active_on = ? ", portal_id, Time.now])

    return bought if bought

    # se lo regalamos al que más karma haya generado en los últimos 3 días en
    # toda la red y no haya sido elegido ayer.
    cool_guys = User.db_query(
        SQL_CANDIDATES % [portal_id, User::STATES_CAN_LOGIN.join(",")])

    # TODO añadir más razones para ser premiado
    if cool_guys.size > 0
      bu = User.find(cool_guys[0]['user_id'].to_i)
      bought = OutstandingUser.create(
          :portal_id => portal_id,
          :active_on => Time.now,
          :entity_id => bu.id,
          :reason => (
              "<strong>#{cool_guys[0]['sum']}</strong> puntos de karma en 3" +
              " días")
      )
      if bought.new_record?
        Rails.logger.warn(
            "Error giving an outstanding user for free:" +
            " #{bought.errors.full_messages_html}")
      end
    end
    bought
  end
end
