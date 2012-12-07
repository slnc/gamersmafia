# -*- encoding : utf-8 -*-
# ContentAttribute:
# - home_image (varchar)
class Tutorial < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable

  file_column :home_image
end
