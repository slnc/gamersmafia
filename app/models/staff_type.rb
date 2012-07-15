# -*- encoding : utf-8 -*-
class StaffType < ActiveRecord::Base
  validates_uniqueness_of :name
end
