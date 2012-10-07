# -*- encoding : utf-8 -*-
class PublishingDecision < ActiveRecord::Base
  VALID_SQL = "(is_right = 't' OR is_right IS NULL)"
  belongs_to :user
  belongs_to :content
  after_save :recalculate_publishing_personality
  plain_text :deny_reason
  validates_uniqueness_of :content_id, :scope => :user_id

  # content is News, etc
  # Devuelve la suma de los pesos actuales de un contenido
  def self.find_sum_for_content(content, return_mixed=false)
    # Nota: es vital poner el user_weight pq para que los tests pasen
    # limpiamente permitimos pesos negativos en exp de un usuario con un tipo
    # de contenido concreto
    publish_sum = User.db_query("SELECT sum(user_weight) FROM publishing_decisions WHERE content_id = #{content.unique_content.id} AND user_weight > 0 AND publish = 't'")[0]['sum'].to_f
    deny_sum = User.db_query("SELECT sum(user_weight) FROM publishing_decisions WHERE content_id = #{content.unique_content.id} AND user_weight > 0 AND publish = 'f'")[0]['sum'].to_f
    if return_mixed
      [publish_sum, deny_sum]
    else
      return publish_sum - deny_sum
    end
  end

  def self.find_voters_count_for_content(content)
    User.db_query("SELECT count(user_id) FROM publishing_decisions WHERE content_id = #{content.unique_content.id}")[0]['count'].to_i
  end

  def recalculate_publishing_personality
    personality.recalculate
  end

  def personality
    PublishingPersonality.find_or_create(self.user, self.content.content_type)
  end
end
