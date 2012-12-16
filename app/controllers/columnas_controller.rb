# -*- encoding : utf-8 -*-
class ColumnasController < InformacionController
  COLUMNS_PER_PAGE = 15
  acts_as_content_browser :column
end
