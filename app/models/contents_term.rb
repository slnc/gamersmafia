class ContentsTerm < ActiveRecord::Base
  belongs_to :content
  belongs_to :term
  validates_presence_of :content_id, :term_id
end
