# -*- encoding : utf-8 -*-
class CoveragesController < ApplicationController
  acts_as_content_browser :coverage
  allowed_portals [:gm, :faction, :arena]
end
