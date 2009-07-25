class News < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable

  has_one :content, :foreign_key => 'external_id'

  belongs_to :content, :foreign_key => 'external_id'
  
  validates_format_of :source, :with => Cms::URL_REGEXP_FULL, :if => Proc.new { |c| c.source.to_s != '' }
end
