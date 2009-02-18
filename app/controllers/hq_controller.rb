class HqController < ApplicationController
  before_filter do |c|
    raise AccessDenied unless c.user && c.user.is_hq?
  end
  
  def bans_requests
    @title = "Histórico de peticiones de bans/unbans"
  end
  
  def antifloods
    @title = "Antifloods activos"
  end
  
  def slog_archive
    @title = "Histórico de sucesos"
  end
end
