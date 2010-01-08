class ContentsTerm < ActiveRecord::Base
  belongs_to :content
  belongs_to :term
  validates_presence_of :content_id, :term_id
  validates_uniqueness_of :content_id, :scope => :term_id
end
