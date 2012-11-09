# -*- encoding : utf-8 -*-
class NotificationObserver < ActiveRecord::Observer
  observe AbTest,
          BanRequest,
          Content,
          NeReference,
          Question,
          SoldOutstandingClan,
          SoldOutstandingUser,
          UsersEmblem,
          UsersSkill

  def after_create(o)
    case o.class.name
    when 'AbTest'
      recipient = User.find(App.webmaster_user_id)
      recipient.notifications.create({
          :description => (
              "AB Test '#{o.name}' creado automáticamente con #{o.treatments}
              tratamientos"),
          :type_id => Notification::AUTOMATIC_AB_TEST,
      })

    when 'BanRequest'
      UsersSkill.find_users_with_skill("Capo").each do |user|
        next if user.id == o.user_id
        user.notifications.create({
          :description => (
              "Iniciado <a href=\"/admin/usuarios/confirmar_ban_request/#{o.id}
              \">ban contra #{o.banned_user.login}</a>"),
          :type_id => Notification::BAN_REQUEST_INITIATED,
        })
      end

    when 'NeReference'
      case o.entity_class
      when "User"
        handle_user_reference(o)
      when "Clan"
        # We don't do anything yet here
      else
        raise "Unknown reference entity_class '#{o.entity_class}'"
      end

    when 'UsersEmblem'
      o.user.notifications.create({
        :description => (
            "Acabas de obtener el emblema #{o.inline_html}.
            ¡Enhorabuena!"),
        :type_id => Notification::USERS_EMBLEM_RECEIVED,
      })

    when 'UsersSkill'
      o.user.notifications.create({
        :description => (
            "Acabas de obtener la habilidad <strong>#{o.format_scope}</strong>.
            ¡Enhorabuena!"),
        :type_id => Notification::USERS_SKILL_RECEIVED,
      })

    end
  end

  def send_denied_content_notification(content)
    msg = "Lo lamentamos pero tu contenido ha sido denegado. <a href=\"/decisiones\">Más información</a>."
    content.user.notifications.create({
      :description => msg,
      :sender_user_id => Ias.MrMan,
      :type_id => Notification::CONTENT_DENIED,
    })
  end

  def after_save(o)
    case o.class.name
    when 'Content'
      if (o.state_changed? && o.state == Cms::DELETED &&
          o.state_was == Cms::PENDING)
        self.send_denied_content_notification(o)
      end

    when 'Question'
      if o.answered_on_changed?
        if o.accepted_answer_comment_id.nil?
          recipient = o.user
          description = (
              "Tu pregunta <a href=\"#{Routing.gmurl(o)}\">\"#{o.title}\"</a>
              ha sido cerrada sin una respuesta por ser cancelada o por llevar
              abierta demasiado tiempo.")
        else
          recipient = o.best_answer.user
          description = (
              "¡Enhorabuena! La mejor respuesta a
              <a href=\"#{Routing.gmurl(o)}\">\"#{o.title}\"</a> ha sido tuya")
          if o.prize > 0
            description = (
                "#{description} por lo que te llevas la recompensa de" +
                " #{o.prize} GMFs.")
          else
            description = "#{description}."
          end
        end
        recipient.notifications.create({
            :description => description,
            :type_id => Notification::BEST_ANSWER_RECEIVED,
        })
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
          :type_id => Notification::OUTSTANDING_CLAN_SCHEDULED,
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
          :type_id => Notification::OUTSTANDING_USER_SCHEDULED,
      })
    end
  end

  def after_destroy(o)
    case o.class.name
    when 'NeReference'
      case o.entity_class
      when "User"
        handle_user_reference_destroy(o)
      when "Clan"
        # We don't do anything yet here
      else
        raise "Unknown reference entity_class '#{o.entity_class}'"
      end

    when 'UsersSkill'
      o.user.notifications.create({
        :description => (
            "Has perdido la habilidad de
            <strong>#{o.format_scope}</strong>"),
        :type_id => Notification::USERS_SKILL_LOST,
      })
    end
  end

  private
  def handle_user_reference(reference)
    user = User.find(reference.entity_id)
    return if user.pref_radar_notifications.to_i != 1

    case reference.referencer_class
    when "Comment"
      comment = Comment.find(reference.referencer_id)
      if comment.user_id != reference.entity_id
        notification = user.notifications.with_type(
            Notification::NICK_REFERENCE_IN_COMMENT).find(
                :first, :conditions => ["data = ?", comment.id.to_s])
        return if notification

        user.notifications.create({
          :description => (
              "<a href=\"#{Routing.gmurl(comment.user)}\">#{comment.user.login}</a>
              te ha nombrado en <a href=\"#{Routing.gmurl(comment)}\">este
              comentario</a>."),
          :type_id => Notification::NICK_REFERENCE_IN_COMMENT,
          :data => comment.id.to_s,
        })
      end
    else
      raise "Unknown referencer_class '#{reference.referencer_class}'"
    end
  end

  def handle_user_reference_destroy(reference)
    user = User.find(reference.entity_id)
    return if user.pref_radar_notifications.to_i != 1

    case reference.referencer_class
    when "Comment"
      comment = Comment.find(reference.referencer_id)
      notification = user.notifications.with_type(
          Notification::NICK_REFERENCE_IN_COMMENT).find(
              :first, :conditions => ["data = ?", comment.id.to_s])
      notification.destroy if notification
    else
      raise "Unknown referencer_class '#{reference.referencer_class}'"
    end
  end
end
