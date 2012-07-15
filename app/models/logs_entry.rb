# -*- encoding : utf-8 -*-
class LogsEntry < ActiveRecord::Base
  @abstract_class = true

  plain_text :message

  validates_length_of :message, :within => 3..200

  before_save :truncate_message

  def truncate_message
    self.message = self.message[0..99]
  end
end
