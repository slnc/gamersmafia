class SentEmail < ActiveRecord::Base
  validates_presence_of :message_key
  validates_uniqueness_of :message_key
end
