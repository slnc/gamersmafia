class RssController < ApplicationController

  def noticias
      response.headers["Content-Type"] = 'text/xml'
      render :layout => false
  end
end
