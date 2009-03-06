class EncuestasController < ComunidadController
  acts_as_content_browser :poll
  allowed_portals [:gm, :faction, :clan, :bazar_district, :bazar]
  
  def new
    require_auth_users
    @title = 'Nueva encuesta'
    @pending = Poll.pending
    @poll = Poll.new #({:starts_on => 1.hour.since, :ends_on => 7.days.since})
    one_hour_since = 2.hours.since
    if @user.faction_id then
      last = Term.single_toplevel(:slug => @user.faction.code).find(:published, :content_type => 'Poll', :order => 'created_on DESC', :limit => 1)
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
    if user_is_authed:
      @poll.vote(@polls_option, self.request.remote_ip, @user.id)
    else
      @poll.vote(@polls_option, self.request.remote_ip)
    end
    flash[:notice] = 'Voto realizado correctamente'
    # TODO esto no hay que hacerlo aquí
    @poll.get_related_portals.each do |p| 
      CacheObserver.expire_fragment("/#{p.code}/encuestas/index/most_votes")
      CacheObserver.expire_fragment("/#{p.code}/home/index/polls") # TODO
    end
    
    redirect_to gmurl(@poll)
  end
end
