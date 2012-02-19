class EventosController < ApplicationController
  acts_as_content_browser :event
  PER_PAGE = 20
  #verify :method => :post, :only => [ :member_join, :member_leave ], :redirect_to => '/eventos'

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
