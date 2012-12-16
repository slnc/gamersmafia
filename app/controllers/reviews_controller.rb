# -*- encoding : utf-8 -*-
class ReviewsController < InformacionController
  acts_as_content_browser :review
end
