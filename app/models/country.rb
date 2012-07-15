# -*- encoding : utf-8 -*-
class Country < ActiveRecord::Base
  has_many :users
end
