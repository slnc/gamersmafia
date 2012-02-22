class EventosController < ApplicationController
  acts_as_content_browser :event
  PER_PAGE = 20

  def member_join
    require_auth_users
    e = Event.find(params[:id])
    e.member_join(@user)
    @js_response = (
        "create_member_link('user#{@user.id}', '#{@user.login}');" +
        " $j('#join-link').hide(); $j('#leave-link').show();")
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end

  def member_leave
    require_auth_users
    e = Event.find(params[:id])
    e.member_leave(@user)
    @js_response = (
        "$j('#user#{@user.id}').fadeOut('normal'); $j('#leave-link').hide();" +
        " $j('#join-link').show();")
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end
end
