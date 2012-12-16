# -*- encoding : utf-8 -*-
class NoticiasController < InformacionController
  NEWS_PER_PAGE = 20
  acts_as_content_browser :news
end
