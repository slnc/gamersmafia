class SkinsFile < ActiveRecord::Base
  file_column :file
  belongs_to :skin
end
