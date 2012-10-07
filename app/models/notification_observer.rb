# -*- encoding : utf-8 -*-
class NotificationObserver < ActiveRecord::Observer
  observe AbTest,
          BanRequest,
          Question,
          SoldOutstandingClan,
          SoldOutstandingUser,
          UsersSkill

  def after_create(o)
    case o.class.name
    when 'AbTest'
      recipient = User.find(App.webmaster_user_id)
      recipient.notifications.create({
          :description => (
              "AB Test '#{o.name}' creado automáticamente con #{o.treatments}
              tratamientos"),
      })

    when 'BanRequest'
      UsersSkill.find_users_with_skill("Capo").each do |user|
        next if user.id == o.user_id
        user.notifications.create({
          :description => (
              "Iniciado <a href=\"/admin/usuarios/confirmar_ban_request/#{o.id}
              \">ban contra #{o.banned_user.login}</a>"),
        })
      end

    when 'UsersSkill'
      o.user.notifications.create({
        :description => (
            "Acabas de obtener la habilidad <strong>#{o.format_scope}</strong>.
            ¡Enhorabuena!"),
      })

    end
  end

  def after_save(o)
    case o.class.name
    when 'Question'
      if o.answered_on_changed?
        if o.accepted_answer_comment_id.nil?
          recipient = o.user
          description = (
              "Tu pregunta <a href=\"#{Routing.gmurl(o)}\˝>\"#{o.title}\"</a>
              ha sido cerrada sin una respuesta por ser cancelada o por llevar
              abierta demasiado tiempo.")
        else
          recipient = o.best_answer.user
          description = (
              "¡Enhorabuena! La mejor respuesta a
              <a href=\"#{Routing.gmurl(o)}\˝>\"#{o.title}\"</a> ha sido tuya
              por lo que te llevas la recompensa de #{o.prize} GMFs."
          )
        end
        recipient.notifications.create(:description => description)
      end

    when 'SoldOutstandingClan'
      return if !(o.used_changed? && o.used?)

      oe = OutstandingClan.last
      o.user.notifications.create({
        :description => (
            "El producto \"Clan destacado\" que acabas de comprar estará
            activo durante todo el día
            #{oe.active_on.strftime('%d de %B de %Y')} en portada de
            #{oe.portal.name}."),
      })

    when 'SoldOutstandingUser'
      return if !(o.used_changed? && o.used?)

      oe = OutstandingUser.last
      o.user.notifications.create({
        :description => (
            "El producto \"Usuario destacado\" que acabas de comprar estará
            activo durante todo el día
            #{oe.active_on.strftime('%d de %B de %Y')} en portada de
            #{oe.portal.name}."),
      })
    end
  end

  def after_destroy(o)
    case o.class.name
    when 'UsersSkill'
      o.user.notifications.create({
        :description => (
            "Has perdido la habilidad de
            <strong>#{o.format_scope}</strong>"),
      })
    end
  end
end
