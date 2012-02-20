class Coverage < ActiveRecord::Base
  acts_as_content
  belongs_to :event

  has_one :content, :foreign_key => 'external_id'
  validates_presence_of :title, :event_id

  def main_category
    event.main_category
  end
end
