# -*- encoding : utf-8 -*-
class GruposController < ApplicationController

  def index
  end

  def grupo
    @group = Group.find(params[:id])
  end
end
