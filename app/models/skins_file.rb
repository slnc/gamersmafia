class SkinsFile < ActiveRecord::Base
  file_column :file
  belongs_to :skin
  validates_presence_of :file
end
