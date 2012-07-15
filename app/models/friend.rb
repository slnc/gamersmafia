# -*- encoding : utf-8 -*-
class Friend < User
  has_and_belongs_to_many :users
end
