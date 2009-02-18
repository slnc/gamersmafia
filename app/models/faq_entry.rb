class FaqEntry < ActiveRecord::Base
  belongs_to :faq_category
  before_create :set_position
  
  observe_attr :faq_category_id
  before_save :check_category_id_changed
  
  private 
  def set_position
    self.position = User.db_query("SELECT coalesce(max(position),0) as max from faq_entries WHERE faq_category_id = #{self.faq_category_id.to_i}")[0]['max'].to_i + 1
  end
  
  def check_category_id_changed
    if self.slnc_changed?(:faq_category_id)
      set_position
    end
  end
end
