class EmblemasController < ApplicationController
  def index
  end

  def emblema
    @emblem_info = UsersEmblem::EMBLEMS_INFO[params[:id]]
    raise ActiveRecord::RecordNotFound if @emblem_info.nil?
    @users_emblems = UsersEmblem.emblem(params[:id]).find(
        :all, :order => 'created_on DESC', :limit => 50, :include => :user)
  end
end
