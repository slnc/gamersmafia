class DistritoController < ApplicationController
  before_filter :populate_cur_district
  def index
  end
  
  protected
  def populate_cur_district
    @cur_district = BazarDistrict.find_by_code(@portal.code)
    @active_sawmode = 'bazar'
    raise ActiveRecord::RecordNotFound unless @cur_district
  end
end
