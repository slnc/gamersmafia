# -*- encoding : utf-8 -*-
class DictionaryWord < ActiveRecord::Base
  validates_uniqueness_of :name
end
