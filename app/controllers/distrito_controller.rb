# -*- encoding : utf-8 -*-
class DistritoController < ApplicationController
  def index
  end

  protected
  def populate_cur_district
    @cur_district = BazarDistrict.find_by_slug!(params[:id])
  end
end
