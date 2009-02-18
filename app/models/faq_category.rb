class FaqCategory < ActiveRecord::Base
  has_many :faq_entries, :dependent => :destroy
  acts_as_rootable
  acts_as_tree :order => 'position'
  
  before_create :set_position
  
  private 
  def set_position
    self.position = User.db_query("SELECT coalesce(max(position),0) as max from faq_categories")[0]['max'].to_i + 1
  end
end
