class ContentsTerm < ActiveRecord::Base
  belongs_to :content
  belongs_to :term
  validates_presence_of :content_id, :term_id
  validates_uniqueness_of :content_id, :scope => :term_id

  def import_mode
    @_import_mode || false
  end

  def set_import_mode
    @_import_mode = true
  end
end
