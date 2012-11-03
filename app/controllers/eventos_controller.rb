# -*- encoding : utf-8 -*-
class EventosController < ApplicationController
  acts_as_content_browser :event
  PER_PAGE = 20

  def member_join
    require_auth_users
    e = Event.find(params[:id])
    e.member_join(@user)
    @js_response = (
        "create_member_link('user#{@user.id}', '#{@user.login}');" +
        " $('#join-link').hide(); $('#leave-link').show();")
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end

  def member_leave
    require_auth_users
    e = Event.find(params[:id])
    e.member_leave(@user)
    @js_response = (
        "$('#user#{@user.id}').fadeOut('normal'); $('#leave-link').hide();" +
        " $('#join-link').show();")
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end
end
