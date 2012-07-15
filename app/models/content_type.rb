# -*- encoding : utf-8 -*-
class ContentType < ActiveRecord::Base
    has_many :contents
    has_many :factions_editors

    def self.find_by_name(name)
      find(:first, :conditions => ['LOWER(name) = LOWER(?)', name])
    end

    def name_translated
      Cms::CLASS_NAMES[name].capitalize
    end
end
