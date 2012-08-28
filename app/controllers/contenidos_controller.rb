# -*- encoding : utf-8 -*-
class ContenidosController < ApplicationController
  def show
    @content = Content.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @content
    @content = @content.real_content
    render :layout => 'mobile'
  end

  def redir
    @content = Content.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @content
    redirect_to Routing.gmurl(@content)
  end
end
