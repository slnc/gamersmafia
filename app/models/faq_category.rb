class FaqCategory < ActiveRecord::Base
  has_many :faq_entries, :dependent => :destroy
  acts_as_rootable
  acts_as_tree :order => 'position'
  
  before_create :set_position
  
  def moveup
    @prev = FaqCategory.find(:first, :conditions => ['position < ?', self.position], :order => 'position DESC', :limit => 1)
    if @prev
      @prev.update_attributes(:position => self.position)
      self.update_attributes(:position => @prev.position)
    end
  end
  
  def movedown
    @prev = FaqCategory.find(:first, :conditions => ['position > ?', self.position], :order => 'position ASC', :limit => 1)
    if @prev
      @prev.update_attributes(:position => self.position)
      self.update_attributes(:position => @prev.position)
    end
  end
  
  private 
  def set_position
    self.position = User.db_query("SELECT coalesce(max(position),0) as max from faq_categories")[0]['max'].to_i + 1
  end
end
