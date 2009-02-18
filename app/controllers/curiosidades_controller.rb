class CuriosidadesController < BazarController
  acts_as_content_browser :funthing
  allowed_portals [:gm, :faction, :bazar]
end
