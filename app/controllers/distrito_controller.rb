# -*- encoding : utf-8 -*-
class DistritoController < ApplicationController
  before_filter :populate_cur_district

  def index
  end

  protected
  def populate_cur_district
    @cur_district = BazarDistrict.find_by_slug(@portal.code)
    raise ActiveRecord::RecordNotFound unless @cur_district
  end
end
