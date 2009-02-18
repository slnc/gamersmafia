class ReviewsController < InformacionController
  acts_as_content_browser :review
  allowed_portals [:gm, :faction, :bazar_district]
end
