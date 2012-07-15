# -*- encoding : utf-8 -*-
class OutstandingClan < OutstandingEntity
  # TODO(slnc): cambiar la query para darle el premio al clan del que más se
  # hable o más partidas gane.
  SQL_COOL_CLANS = <<-END
SELECT (
  SELECT clan_id
  FROM portals
  WHERE id = stats.portals.portal_id)
FROM stats.portals
WHERE created_on >= now() - '14 days'::interval
AND portal_id in (
  SELECT id
  FROM portals
  WHERE clan_id IS NOT NULL)
GROUP BY portal_id
HAVING SUM(karma) > 0
ORDER BY SUM(karma) DESC
LIMIT 1
  END

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
    # Temporarily disabled as there are no clan websites anymore.
    return nil
    bought = OutstandingClan.find(
        :first,
        :conditions => ["portal_id = ? AND active_on = ? ", portal_id, Time.now])

    return bought unless bought.nil?

    # se lo regalamos al que más karma haya generado en los últimos 3 días en
    # toda la red y no haya sido elegido ayer.
    # TODO cambiar la query para regalárselo al clan que más karma genere
    cool_clanz = User.db_query(SQL_COOL_CLANS)

    if cool_clans.size > 0 then
      bu = Clan.find(cool_clanz['clan_id'].to_i)
      bought = OutstandingClan.create(
          :portal_id => portal_id,
          :active_on => Time.now,
          :entity_id => bu.id,
          :reason => (
              "<strong>#{cool_guys[0]['sum']}</strong> visitas en la última" +
              " semana")
      )
      if bought.new_record?
        Rails.logger.warn(
            "Error giving an outstanding clan for free:" +
            " #{bought.errors.full_messages_html}")
      end
    end
    bought
  end
end
