class NoticiasController < InformacionController
  NEWS_PER_PAGE = 20
  acts_as_content_browser :news
  allowed_portals [:gm, :faction, :clan, :bazar, :bazar_district]
end
