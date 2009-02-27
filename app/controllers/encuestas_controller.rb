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
      last = Poll.find(:first, :conditions => "polls_category_id = (SELECT id FROM polls_categories WHERE root_id = id and code = '#{@user.faction.code}')", :order => 'ends_on DESC')
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
    p params
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
    #expire_fragment(:controller => 'home', :action => 'index', :part => 'polls')
    #expire_fragment(:controller => 'home', :action => 'index', :part => "polls_#{@poll.my_faction.id}") if @poll.my_faction
    redirect_to gmurl(@poll)
  end
  
  def update
    # TODO hay que usar el update común, esto está buscando bugs a gritos
    @poll = Poll.find(params[:id])
    require_user_can_edit(@poll)
    raise ContentLocked if @poll.is_locked_for_user?(@user)
    
    @poll.cur_editor = @user
    @poll.state = Cms::PENDING if @poll.state == Cms::DRAFT and not params[:draft].to_s == '1'
    if @poll.update_attributes(params[:poll])
      @poll.process_wysiwyg_fields
      params[:options_new].each { |s| @poll.polls_options.create({:name => s}) unless s.strip == '' } if params[:options_new]
      params[:options_delete].each { |id| @poll.polls_options.find(id).destroy if @poll.polls_options.find_by_id(id) } if params[:options_delete]
      params[:options].keys.each do |id| 
        option = @poll.polls_options.find_by_id(id.to_i)
        if option && option.name != params[:options][id]
          option.name = params[:options][id]
          option.save
        end
      end if params[:options]
      
      expire_fragment(:controller => 'home', :action => 'index', :part => 'polls')
      expire_fragment(:controller => 'home', :action => 'index', :part => "polls_#{@poll.my_faction.id}") if @poll.my_faction
      flash[:notice] = 'Encuesta actualizada correctamente.'
      if @poll.state == Cms::PENDING && params[:publish_content] == '1'
        Cms::publish_content(@poll, @user)
        flash[:notice] += "\nContenido publicado correctamente. Gracias."
      end
      if @poll.is_public? then
        redirect_to gmurl(@poll)
      else
        redirect_to :action => 'edit', :id => @poll
      end
    else
      flash[:error] = "Error al actualizar la encuesta: #{@poll.errors.full_messages_html}"
      render :action => 'edit'
    end
  end
end
