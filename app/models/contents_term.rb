# -*- encoding : utf-8 -*-
class ContentsTerm < ActiveRecord::Base
  after_create :schedule_recommendations
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

  def schedule_recommendations
    Crs.delay.recommend_from_contents_term(self)
  end
end
