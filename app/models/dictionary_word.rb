class DictionaryWord < ActiveRecord::Base
  validates_uniqueness_of :name
end
