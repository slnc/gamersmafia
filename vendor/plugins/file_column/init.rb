# fix para observers y plugins:
#   http://lunchroom.lunchboxsoftware.com/articles/2005/12/13/plugins-and-observers
# idea tomada del plugin file_column "oficial"
require File.expand_path('lib/slnc_file_column.rb', File.dirname(__FILE__))

ActiveRecord::Base.send :include, SlncFileColumn
ActiveRecord::Base.send :extend, SlncFileColumn::ClassMethods

ActionView::Base.send :include, SlncFileColumnHelper
