class EventosController < ApplicationController
  acts_as_content_browser :event
  PER_PAGE = 20
  verify :method => :post, :only => [ :member_join, :member_leave ], :redirect_to => '/eventos'

  def dia
    # TODO validación
    raise ActiveRecord::RecordNotFound unless params[:id] && params[:id].length == 8
    @t_start = Time.gm(params[:id][0..3], params[:id][4..5], params[:id][6..7])
    @t_end = Time.gm(params[:id][0..3], params[:id][4..5], params[:id][6..7], 23, 59, 59)
    @title = params[:id]
  end

  def member_join
    require_auth_users
    e = Event.find(params[:id])
    e.member_join(@user)
    render :nothing => true
  end

  def member_leave
    require_auth_users
    e = Event.find(params[:id])
    e.member_leave(@user)
    render :nothing => true
  end
end
