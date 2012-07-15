# -*- encoding : utf-8 -*-
class NeReference < ActiveRecord::Base
  validates_uniqueness_of :entity_id, :scope => [:entity_class, :referencer_class, :referencer_id]
end
