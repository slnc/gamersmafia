# fix para observers y plugins: 
#   http://lunchroom.lunchboxsoftware.com/articles/2005/12/13/plugins-and-observers
# idea tomada del plugin file_column "oficial"
require 'slnc_file_column'

ActiveRecord::Base.send :include, SlncFileColumn
ActiveRecord::Base.send :extend, SlncFileColumn::ClassMethods

ActionView::Base.send :include, SlncFileColumnHelper