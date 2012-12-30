# -*- encoding : utf-8 -*-
class OutstandingUser < OutstandingEntity
  # TODO(slnc): this needs to be adapted to use entity stats
  SQL_CANDIDATES = <<-END
SELECT id
FROM users
WHERE cache_karma_points > 0
ORDER BY RANDOM()
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

  def self.current
    bought = OutstandingUser.find(
        :first, :conditions => ["active_on = ? ", Time.now])

    return bought if bought
    self.award_to_someone
  end

  def self.award_to_someone
    # se lo regalamos al que más karma haya generado en los últimos 3 días en
    # toda la red y no haya sido elegido ayer.
    cool_guys = User.db_query(SQL_CANDIDATES)

    # TODO añadir más razones para ser premiado
    if cool_guys.size > 0
      bu = User.find(cool_guys[0]['user_id'].to_i)
      bought = OutstandingUser.create(
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
