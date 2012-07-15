# -*- encoding : utf-8 -*-
class ArticulosController < ApplicationController
  allowed_portals [:gm, :faction, :bazar, :bazar_district]

  def index
  end
end
