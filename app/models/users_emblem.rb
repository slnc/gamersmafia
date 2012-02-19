class UsersEmblem < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :emblem
  validates_uniqueness_of :emblem, :scope => [:user_id, :created_on]

  def index
    Emblems::EMBLEMS[self.emblem.to_sym][:index]
  end
end
