# -*- encoding : utf-8 -*-
# ContentAttribute:
# - home_image (varchar)
class Interview < Content
  acts_as_categorizable

  file_column :home_image
end
