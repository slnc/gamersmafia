class ColumnasController < InformacionController
  COLUMNS_PER_PAGE = 15
  acts_as_content_browser :column
  allowed_portals [:gm, :faction, :bazar, :bazar_district]
end
