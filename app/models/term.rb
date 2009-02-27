class Term < ActiveRecord::Base
  belongs_to :game
  belongs_to :bazar_district
  belongs_to :platform
  belongs_to :clan
  
  has_many :content_terms
  has_many :contents, :through => :content_terms
  
  acts_as_rootable
  acts_as_tree :order => 'name'
  
  validates_format_of :slug, :with => /^[a-z0-9]{1,50}$/
  validates_format_of :name, :with => /^[a-z0-9:[:space:]]{1,50}$/i
  validates_uniqueness_of :name, :scope => [:game_id, :bazar_district_id, :platform_id, :clan_id, :parent_id]
end
