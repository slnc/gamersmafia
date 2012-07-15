# -*- encoding : utf-8 -*-
# This prevents Rails 3.2 from freezing for several seconds on TemplateError
# exceptions. For more info:
#
# http://railski.blogspot.com/2011/05/rails3-leaks-more-memory.html
# http://stackoverflow.com/questions/9200713/rails-3-2-1-calling-undefined-method-in-view-causes-test-to-hang-for-30-second
# http://stackoverflow.com/questions/9225286/helpers-use-a-lot-of-memory-in-rails-3-2
module ActionDispatch
  module Routing
    class RouteSet
      alias inspect to_s
    end
  end
end
