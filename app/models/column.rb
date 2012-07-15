# -*- encoding : utf-8 -*-
class Column < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable

  file_column :home_image
end
