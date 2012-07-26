# -*- encoding : utf-8 -*-
class UsersActionObserver < ActiveRecord::Observer
  observe User, RecruitmentAd, ClansMovement, Clan, Content, ProfileSignature, Friendship, UsersEmblem

  include ApplicationHelper

  def after_create(object)
    case object.class.name
      when 'ProfileSignature'
      data = "#{user_link(object.signer)} le ha firmado a #{user_link(object.user)}."
      # no creamos firma si la última firma fue hace menos de 5 minutos
      if UsersAction.count(:conditions => ['created_on >= now() - \'5\'::interval AND object_id = ? AND user_id = ? AND type_id = ?', object.id, object.signer_user_id, UsersAction::NEW_PROFILE_SIGNATURE_SIGNED]) == 0 then
        UsersAction.create(:user_id => object.user_id, :type_id => UsersAction::NEW_PROFILE_SIGNATURE_SIGNED, :object_id => object.id, :data => data)
        UsersAction.create(:user_id => object.signer_user_id, :type_id => UsersAction::NEW_PROFILE_SIGNATURE_RECEIVED, :object_id => object.id, :data => data)
      end

      when 'RecruitmentAd'
      data = "#{user_link(object.user)} ha publicado <a href=\"#{Routing.gmurl(object)}\">un anuncio de reclutamiento</a>"
      ua = UsersAction.create({
          :user_id => object.user_id,
          :type_id => UsersAction::NEW_RECRUITMENT_AD,
          :object_id => object.id,
          :data => data,
      })

      when 'ClansMovement'
      data = "#{user_link(object.user)} #{ClansMovement.translate_direction(object.direction)} <a href=\"/clanes/clan/#{object.id}\">#{object.clan}</a>"
      UsersAction.create(:user_id => object.user_id, :type_id => UsersAction::NEW_CLANS_MOVEMENT, :object_id => object.id, :data => data)

      when 'UsersEmblem'
      if Emblems::EMBLEMS_TO_REPORT.include?(object.emblem)
        data = "#{user_link(object.user)} ha obtenido el emblema de <strong>#{Emblems::EMBLEMS[object.emblem.to_sym][:title]}</strong>"
        UsersAction.create(:user_id => object.user_id, :type_id => UsersAction::NEW_USERS_EMBLEM, :object_id => object.id, :data => data)
      end

      when 'Clan'
      if object.creator_user_id
        data = "#{user_link(object.creator)} ha creado un nuevo clan: <a href=\"#{gmurl(object)}\">#{object.name}</a>"
        UsersAction.create(:user_id => object.creator_user_id, :type_id => UsersAction::NEW_CLAN, :object_id => object.id, :data => data)
      end
    end
  end

  def after_save(object)
    case object.class.name
      when 'Content'
      if object.state_changed?
        if object.state == Cms::PUBLISHED

          # TODO si es foto poner thumbnail
          data = "#{user_link(object.user)} ha publicado <a href=\"#{gmurl(object)}\">#{Cms.faction_favicon(object)} "
          if object.real_content.class.name == 'Image'
            data << "<img src=\"/cache/thumbnails/i/32x32/#{object.real_content.file}\" />"
          else
            data << "#{object.name}"
          end
          data << '</a>'

          UsersAction.create(:user_id => object.user_id, :type_id => UsersAction::NEW_CONTENT, :object_id => object.id, :data => data)
        elsif object.state == Cms::DELETED
          UsersAction.find(:all, :conditions => ['type_id = ? AND object_id = ?', UsersAction::NEW_CONTENT, object.id]).each { |ra| ra.destroy }
        end
      end

      when 'User'
      if object.photo_changed?
        if UsersAction.count(:conditions => ['created_on >= now() - \'5\'::interval AND user_id = ? AND type_id = ?', object.id, UsersAction::PROFILE_PHOTO_UPDATED]) == 0 then
          u = User.find(object.id) # para que photo tenga ya la ruta
          UsersAction.create(:user_id => object.id,
                             :type_id => UsersAction::PROFILE_PHOTO_UPDATED,
                             :data => "#{user_link(object)} ha actualizado la foto de su perfil <img src=\"/cache/thumbnails/i/32x32/#{u.photo}\" />")
        end
      end

      if object.faction_id_changed?
        msg = object.faction_id ? "se ha pasado a la facción de <a href=\"/facciones/show/#{object.faction_id}\">#{object.faction.name}</a>" : "ha dejado de pertenecer a cualquier facción"
        UsersAction.create(:user_id => object.id,
                           :type_id => UsersAction::USER_CHANGED_TO_NEW_FACTION,
                           :data => "#{user_link(object)} #{msg}")
      end

      when 'RecruitmentAd'
      if object.deleted_changed?
        UsersAction.find(
            :all,
            :conditions => ['type_id = ? AND object_id = ?',
                            UsersAction::NEW_RECRUITMENT_AD,
                            object.id]).each { |ra| ra.destroy }
      end

      when 'Friendship'
      if object.accepted_on_changed? && !object.accepted_on.nil?
        UsersAction.create(:user_id => object.sender_user_id,
                           :type_id => UsersAction::NEW_FRIENDSHIP_SENDER,
                           :object_id => object.id,
                           :data => "#{user_link(object.sender)} y #{user_link(object.receiver)} son ahora amigos")
        UsersAction.create(:user_id => object.receiver_user_id,
                           :type_id => UsersAction::NEW_FRIENDSHIP_RECEIVER,
                           :object_id => object.id,
                           :data => "#{user_link(object.receiver)} y #{user_link(object.sender)} son ahora amigos")
      end

      when 'Clan'
      if object.deleted_changed? && object.creator_user_id
        UsersAction.find(:all, :conditions => ['type_id = ? AND object_id = ?', UsersAction::NEW_CLAN, object.id]).each { |ra| ra.destroy }
      end
    end
  end

  def after_destroy(object)
    case object.class.name
      when 'ProfileSignature'
      UsersAction.find(:all, :conditions => ['type_id = ? AND object_id = ?', UsersAction::NEW_PROFILE_SIGNATURE_SIGNED, object.id]).each { |ra| ra.destroy }
      UsersAction.find(:all, :conditions => ['type_id = ? AND object_id = ?', UsersAction::NEW_PROFILE_SIGNATURE_RECEIVED, object.id]).each { |ra| ra.destroy }
      when 'Friendship'
      UsersAction.find(:all, :conditions => ['type_id = ? AND object_id = ?', UsersAction::NEW_FRIENDSHIP_SENDER, object.id]).each { |ra| ra.destroy }
      UsersAction.find(:all, :conditions => ['type_id = ? AND object_id = ?', UsersAction::NEW_FRIENDSHIP_RECEIVER, object.id]).each { |ra| ra.destroy }
      when 'ClansMovement'
      UsersAction.find(:all, :conditions => ['type_id = ? AND object_id = ?', UsersAction::NEW_CLANS_MOVEMENT, object.id]).each { |ra| ra.destroy }
      when 'UsersEmblem'
      UsersAction.find(:all, :conditions => ['type_id = ? AND object_id = ?', UsersAction::NEW_USERS_EMBLEM, object.id]).each { |ra| ra.destroy }
      # TODO
      #Faith.reset(object.referer) if object.referer_user_id # no hacemos lo siguiente porque ahora mismo no controlamos muy bien cuándo pasa de un estado a otro y los puntos de fe asociados.
      #Faith.reset(object.resurrector) if object.resurrected_by_user_id && (object.referer_user_id.nil? || object.referer_user_id != object.resurrected_by_user_id)
      # Faith.take(object.referer, Faith::FPS_ACTIONS['registration']) if object.referer_user_id && object.state != 'zombie'
    end
  end
end
