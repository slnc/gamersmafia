class FaithObserver < ActiveRecord::Observer
  observe ContentRating, User, PublishingDecision, CommentsValoration, UsersContentsTag

  def after_create(object)
    case object.class.name
      when 'CommentsValoration':
      Faith.give(object.user, Faith::FPS_ACTIONS['rating']) if object.user_id

      when 'ContentRating':
      Faith.give(object.user, Faith::FPS_ACTIONS['rating']) if object.user_id

      when 'UsersContentsTag':
      Faith.give(object.user, Faith::FPS_ACTIONS['users_contents_tag']) if object.user_id
    end
  end


  def after_save(object)
    case object.class.name
      when 'PublishingDecision':
      Faith.reset(object.user)

      when 'User':
      if object.state_changed?
        if object.referer_user_id
          Faith.reset(object.referer)
          # No hacemos lo siguiente porque ahora mismo no controlamos muy bien
          # cuándo pasa de un estado a otro y los puntos de fe asociados.
        end
        if (object.resurrected_by_user_id &&
            (object.referer_user_id.nil? ||
             object.referer_user_id != object.resurrected_by_user_id))
          Faith.reset(object.resurrector)
        end
      end
    end
  end

  def after_destroy(object)
    case object.class.name
      when 'CommentsValoration':
      Faith.take(object.user, Faith::FPS_ACTIONS['rating'])

      when 'ContentRating':
      Faith.take(object.user, Faith::FPS_ACTIONS['rating'])

      when 'UsersContentsTag':
      Faith.take(object.user, Faith::FPS_ACTIONS['users_contents_tag'])

      when 'User':
      # TODO
      Faith.reset(object.referer) if object.referer_user_id # no hacemos lo siguiente porque ahora mismo no controlamos muy bien cuándo pasa de un estado a otro y los puntos de fe asociados.
      Faith.reset(object.resurrector) if object.resurrected_by_user_id && (object.referer_user_id.nil? || object.referer_user_id != object.resurrected_by_user_id)
      # Faith.take(object.referer, Faith::FPS_ACTIONS['registration']) if object.referer_user_id && object.state != 'zombie'
    end
  end
end
