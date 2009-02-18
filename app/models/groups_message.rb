class GroupsMessage < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :title
  plain_text :title
end
