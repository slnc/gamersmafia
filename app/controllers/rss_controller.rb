# -*- encoding : utf-8 -*-
class RssController < ApplicationController

  TIMEZONE = '+0100'

  def noticias
    @timezone = TIMEZONE
    response.headers["Content-Type"] = 'text/xml'
    render :layout => false
  end
end
