class GmtvController < ApplicationController

  def channels
    response.headers["Content-Type"] = "application/xhtml+xml"
    response.headers['Pragma'] = 'no-cache'
    response.headers["Cache-Control"] = "no-cache, must-revalidate"

    render :layout => false
  end
end
