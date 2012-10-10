# -*- encoding : utf-8 -*-
class PublishingDecision < ActiveRecord::Base
  VALID_SQL = "(is_right = 't' OR is_right IS NULL)"
  belongs_to :user
  belongs_to :content
  after_save :recalculate_publishing_personality
  plain_text :deny_reason
  validates_uniqueness_of :content_id, :scope => :user_id

  # Creates or updates a publishing decision on a given content.
  def self.create_or_update_decision(user, uniq, do_we_publish, reason)
    u_weight = Cms::get_user_weight_with(
        uniq.content_type, user, uniq.real_content)

    if u_weight == Infinity
      real_weight = 1.0
    else
      real_weight = u_weight
    end

    pd = PublishingDecision.find(
        :first,
        :conditions => ['user_id = ? and content_id = ?', user.id, uniq.id])

    if do_we_publish
      deny_reason = nil
      publish_reason = reason
    else
      deny_reason = reason
      publish_reason = nil
    end

    common_attributes = {
        :accept_comment => reason,
        :deny_reason => reason,
        :publish => do_we_publish,
        :user_weight => real_weight,
    }

    if pd.nil?
      merged_attrs = common_attributes.merge({
          :content_id => uniq.id,
          :user_id => user.id,
      })
      pd = PublishingDecision.create(merged_attrs)
    else
      pd.update_attributes(common_attributes)
    end
    pd
  end

  # content is News, etc
  # Devuelve la suma de los pesos actuales de un contenido
  def self.find_sum_for_content(content, return_mixed=false)
    # Nota: es vital poner el user_weight pq para que los tests pasen
    # limpiamente permitimos pesos negativos en exp de un usuario con un tipo
    # de contenido concreto
    publish_sum = User.db_query(
        "SELECT SUM(user_weight)
        FROM publishing_decisions
        WHERE content_id = #{content.unique_content.id}
        AND user_weight > 0
        AND publish = 't'")[0]['sum'].to_f
    deny_sum = User.db_query(
        "SELECT SUM(user_weight)
        FROM publishing_decisions
        WHERE content_id = #{content.unique_content.id}
        AND user_weight > 0
        AND publish = 'f'")[0]['sum'].to_f

    if return_mixed
      [publish_sum, deny_sum]
    else
      publish_sum - deny_sum
    end
  end

  def self.update_is_right_based_on_state(content)
    content.publishing_decisions.find(:all).each do |pd|
      pd.is_right = (
          (content.state == Cms::PUBLISHED && pd.publish) ||
          (content.state == Cms::DELETED && !pd.publish))
      pd.save
      pd.personality.recalculate
    end
  end

  def self.find_voters_count_for_content(content)
    User.db_query(
        "SELECT count(user_id)
        FROM publishing_decisions
        WHERE content_id = #{content.unique_content.id}")[0]['count'].to_i
  end

  def recalculate_publishing_personality
    personality.recalculate
  end

  def personality
    PublishingPersonality.find_or_create(self.user, self.content.content_type)
  end
end
