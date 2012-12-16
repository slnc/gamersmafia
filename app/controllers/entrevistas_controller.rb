# -*- encoding : utf-8 -*-
class EntrevistasController < InformacionController
  INTERVIEWS_PER_PAGE = 15
  acts_as_content_browser :interview
end
