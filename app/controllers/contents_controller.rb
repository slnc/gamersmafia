# -*- encoding : utf-8 -*-
class ContentsController < ApplicationController
  def show
    @content = Content.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @content
  end

  def redir
    @content = Content.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @content
    redirect_to Routing.gmurl(@content)
  end
end
