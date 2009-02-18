class TemasController < BazarController
  def index
  end

  def tema
    @cat = TopicsCategory.find_by_code(params[:code])
    @portal = BazarDistrictPortal.find_by_code(params[:code])
    raise ActiveRecord::RecordNotFound unless @cat
  end
end
