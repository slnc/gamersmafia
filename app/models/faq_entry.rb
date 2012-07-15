# -*- encoding : utf-8 -*-
class FaqEntry < ActiveRecord::Base
  belongs_to :faq_category
  before_create :set_position
  before_save :check_category_id_changed

  protected
  def set_position
    self.position = User.db_query("SELECT coalesce(max(position),0) as max from faq_entries WHERE faq_category_id = #{self.faq_category_id.to_i}")[0]['max'].to_i + 1
  end

  def check_category_id_changed
    self.set_position if self.faq_category_id_changed?
  end
end
