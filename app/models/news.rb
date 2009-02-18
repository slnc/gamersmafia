class News < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable

  has_one :content, :foreign_key => 'external_id'

  belongs_to :content, :foreign_key => 'external_id'
  
  before_save :do_the_bazar_trick
    
  private
  def do_the_bazar_trick
    @@_bazar_cat ||= NewsCategory.find_by_code('bazar')
    if self.slnc_changed?(:news_category_id) && self.news_category_id == @@_bazar_cat.id
      self.news_category_id = NewsCategory.find(:first, :conditions => 'code = \'inet\'').id
    end
    true
  end
end
