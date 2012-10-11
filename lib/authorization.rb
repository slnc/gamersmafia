# This module determines what actions can different users or clans take.
module Authorization
  # TODO(slnc): migrar todas las llamadas restantes a .has_skill? a que usen
  # este sistema.

  def self.can_access_moderation_queue?(user)
    user.has_skill?("ContentModerationQueue")
  end

  def self.can_access_experiments?(user)
    user.has_skill?("Webmaster")
  end

  def self.can_admin_competition?(u, competition)
    competition.user_is_admin(u.id) || u.has_skill?("Webmaster")
  end

  def self.can_admin_toplevel_terms?(u)
    u.has_any_skill?(%w(BazarManager Capo))
  end

  def self.can_admin_non_root_terms?(user)
    user.has_any_skill?(%w(
        Boss
        Capo
        Don
        Editor
        ManoDerecha
        Sicario
        Underboss
        Webmaster
    ))
  end

  def self.can_access_bank?(user)
    user.has_skill?("Bank")
  end

  def self.can_access_gmshop?(user)
    user.has_skill?("GmShop")
  end

  def self.can_admin_all_items?(user)
    user.has_skill?("Capo")
  end

  def self.can_admin_bazar_districts?(user)
    user.has_skill?("BazarManager")
  end

  def self.can_antiflood_users?(user)
    user.has_skill?("Antiflood")
  end

  def self.can_admin_tags?(user)
    user.has_any_skill?(%w(Capo Webmaster))
  end

  def self.can_bulk_upload?(u)
    u.has_skill?("BulkUpload")
  end

  def self.can_bypass_publish_decision?(user, content)
    user.has_skill?("EditContents")
  end

  def self.can_create_content?(user)
    User::STATES_CAN_LOGIN.include?(user.state) && user.antiflood_level < 5
  end

  def self.can_create_profile_signatures?(user)
    user.has_skill?("ProfileSignatures")
  end

  def self.can_create_term?(u, term, taxonomy)
    self.can_edit_term?(u, term, taxonomy)
  end

  def self.can_delete_content?(user, content)
    user.has_skill?("DeleteContents")
    # TODO(slnc): temporal, hack una vez que limpiemos user_can_edit_content?
    # tenemos que cambiar estas reglas para permitir ciertas combinaciones de
    # usuarios y tipos de contenido. Eg: a autores de entradas de blog borrar
    # sus entradas o a autores de anuncios de reclutamiento borrar sus anuncios.
  end

  def self.can_delete_contents?(user)
    user.has_skill?("DeleteContents")
  end

  def self.can_edit_ad_slot?(user, ads_slot)
  (user.has_skill?("Webmaster") ||
   user.users_skills.count(
       :conditions => "role = 'Advertiser' AND
                       role_data = '#{ads_slot.advertiser_id}'") > 0)
  end

  def self.can_edit_ads_directly?(user)
    user.has_skill?("Webmaster")
  end

  # Can any of the user provided fields be modified? (title, summary, etc)
  # TODO(slnc): simplify this and remove any checks not strictly related to
  # editing user-contributed fields.
  def self.can_edit_content?(user, content)
    return true if user && user.has_skill?("EditContents")
    return false unless user && user.id

    if (content.respond_to?(:state) &&
        content.user_id == user.id &&
        content.state == Cms::DRAFT)
      true
    elsif (content.respond_to?(:state) &&
           content.state == Cms::PENDING &&
           Authorization.can_modify_pending_content?(user))
      true
    elsif (content.class.name == 'Question' &&
           content.user_id == user.id &&
           (content.created_on > 15.minutes.ago ||
            content.unique_content.comments_count == 0))
      true
    elsif (content.class.name == 'RecruitmentAd' &&
           (user.has_skill?("Capo") ||
            user.has_skill?("Bot") ||
            user.id == content.user_id ||
            (content.clan_id && content.clan.user_is_clanleader(user.id))))
      true
    elsif (Cms::AUTHOR_CAN_EDIT_CONTENTS.include?(content.class.name) &&
           content.user_id == user.id)
      true
    elsif content.kind_of?(Coverage) && (c = content.event.competition)
      c.user_is_admin(user.id)
    elsif content.kind_of?(Coverage) then
      Authorization.can_edit_content?(user, content.event)
    elsif content.class.name == 'Topic' or content.class.name == 'Comment'
      # jefazo o moderador de la organization?
      # chequeamos que sea boss, underboss o moderador de la facción
      org = Organizations.find_by_content(content)
      # el autor del topic/comment y no está baneado
      if (content.class.name == 'Topic' &&
          user.id == content.user_id &&
          content.created_on.to_i > 15.minutes.ago.to_i &&
          (org.nil? || !org.user_is_banned?(content.user)))
        true
      elsif org
        if org.user_is_moderator(user)
          true
        elsif content.class.name == 'Comment'
          real = content.content.real_content
          if (real.class.name == 'Event' &&
              (cm = CompetitionsMatch.find_by_event_id(real.id)) &&
              cm.competition.user_is_admin(user.id))
            true
          else
            false
          end
        else # TODO Coverage
          false
        end
      else # categoría Otros o categoría GM
        if (content.respond_to?(:content) &&
            (real = content.content.real_content) &&
            real.class.name == 'Coverage' &&
            (c = Competition.find_by_event_id(real.event_id)) &&
            c.user_is_admin(user.id))
          true
        else
          user.has_skill?("Capo")
        end
      end
    else # editor o jefazo de organization?
      org = Organizations.find_by_content(content)
      if org
        org.user_is_editor_of_content_type?(
            user, ContentType.find_by_name(content.class.name))
      else
        false
      end
    end
  end

  def self.can_edit_faction?(user, faction)
    user.has_skill?("Webmaster") || faction.is_bigboss?(user)
  end

  def self.can_edit_faq?(user)
    user.has_skill?("EditFaq")
  end

  def self.can_edit_term?(u, term, taxonomy)
    return true if u.has_skill?("Capo") || u.has_skill?("Webmaster")
    return false if term.id == term.root_id

    if term.game_id
      f = Faction.find_by_code(term.game.code)
      (f.is_bigboss?(u) ||
       f.user_is_editor_of_content_type?(
           u, ContentType.find_by_name(taxonomy)))
    elsif term.platform_id
      f = Faction.find_by_code(term.platform.code)
      (f.is_bigboss?(u) ||
       f.user_is_editor_of_content_type?(
           u, ContentType.find_by_name(taxonomy)))
    elsif term.bazar_district_id
      f = term.bazar_district
      f.is_bigboss?(u) || f.is_sicario?(u)
    elsif term.clan_id
      c = term.clan
      c.user_is_clanleader(u)
    end
  end

  def self.can_edit_users?(user)
    user.has_any_skill?(%w(Capo Webmaster))
  end

  def self.can_force_recalculate_user_attributes?(user)
    user.has_any_skill?(%w(Capo Webmaster))
  end

  def self.can_mass_moderate_contents?(user)
    user.has_any_skill?(%w(MassModerateContents Capo Webmaster))
  end

  def self.can_moderate_comment?(user, comment)
    user.has_skill?("Capo")
  end

  def self.can_modify_pending_content?(user)
    user.has_skill?("EditContents")
  end

  # Determines whether or not the user can vote whether or not to publish
  # pending contents.
  def self.can_publish_decision?(user, content)
    user.has_skill?("ContentModerationQueue")
  end

  def self.can_rate_comments_down?(user)
    user.has_skill?("RateCommentsDown")
  end

  def self.can_rate_comments_up?(user)
    user.has_skill?("RateCommentsUp")
  end

  def self.can_recover_content?(user, content)
    user.has_skill?("DeleteContents")
  end

  def self.can_report_comments?(user)
    user.has_skill?("ReportComments")
  end

  def self.can_report_contents?(user)
    user.has_skill?("ReportContents")
  end

  def self.can_report_users?(user)
    user.has_skill?("ReportUsers")
  end

  def self.can_see_netiquette_violations?(user)
    user.has_skill?("Capo")
  end

  def self.can_set_best_answer(user, content)
    return false if content.class.name != 'Question'
    user.id == content.user_id || self.can_edit_content?(user, content)
  end

  def self.can_tag_contents?(user)
    user.has_skill?("TagContents")
  end

  def self.gets_less_ads?(user)
    user.has_skill?("LessAds")
  end

  def self.is_advertiser?(user)
    user.has_skill?("Advertiser")
  end

  def self.is_faction_staff?(u, faction)
    (faction.is_big_boss?(u) || faction.is_editor?(u) || u.has_skill?("Capo"))
  end
end
