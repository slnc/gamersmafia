class Event < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable
  acts_as_tree :order => 'title'

  scope :top_level, :conditions => 'parent_id IS NULL'
  scope :current_events, :conditions => "events.starts_on < now() + '2 months'::interval
                                           AND events.parent_id is null
                                           AND events.ends_on > now()
                                           AND events.id not in (SELECT event_id from competitions)",
                               :order => 'starts_on'

  has_one :competition_match
  has_one :competition
  has_many :coverages
  has_and_belongs_to_many :users

  before_validation :check_website_format

  validates_format_of :website,
                      :with => Cms::URL_REGEXP_FULL,
                      :if => Proc.new{ |c| c.website.to_s != '' }

  def check_website_format
    if self[:website] && self[:website].to_s.strip != '' && !(self[:website] =~ /^http:\/\//)
      self[:website] = "http://#{self[:website]}"
    end
  end

  def member_join(u)
    self.users<< u
    self.save
  end

  def member_leave(u)
    self.users.delete(u)
    self.save
  end
end
