class EntrevistasController < InformacionController
  INTERVIEWS_PER_PAGE = 15
  acts_as_content_browser :interview
  allowed_portals [:gm, :faction, :bazar_district]
end
