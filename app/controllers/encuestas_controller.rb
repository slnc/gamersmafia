# -*- encoding : utf-8 -*-
class EncuestasController < InformacionController
  acts_as_content_browser :poll

  def new
    require_auth_users
    @title = 'Nueva encuesta'
    @pending = Poll.pending
    @poll = Poll.new
    one_hour_since = 2.hours.since
    if @user.faction_id then
      faction_root = Term.single_toplevel(:slug => @user.faction.code)
      last = Poll.in_term(faction_root).published.find(
          :all,
          :order => 'created_on DESC',
          :limit => 1)
      last = last.size > 0 ? last[0] : nil
    else
      last = nil
    end

    if last and last.ends_on > one_hour_since then
      @poll.starts_on = last.ends_on
    else
      @poll.starts_on = one_hour_since
    end

    @poll.ends_on = @poll.starts_on + 86400 * 7
  end

  def vote
    @poll = Poll.find(params[:id])

    @polls_option = @poll.polls_options.find(params[:poll_option])
    if user_is_authed
      @poll.vote(@polls_option, self.remote_ip, @user.id)
    else
      @poll.vote(@polls_option, self.remote_ip)
    end
    flash[:notice] = 'Voto realizado correctamente'
    redirect_to gmurl(@poll)
  end
end
