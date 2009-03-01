class ApuestasController < ArenaController
  acts_as_content_browser :bet
  allowed_portals [:gm, :faction, :arena, :bazar, :bazar_district]
  
  def complete
    require_auth_users
    @bet = Bet.find(params[:id])
    require_user_can_edit(@bet)
    raise ActiveRecord::RecordNotFound if (not @bet.is_public? or @bet.closes_on > Time.now or @bet.completed?)
    GmSys.job("Bet.find(#{params[:id]}).complete('#{params[:winner]}')")
    flash[:notice] = "Apuesta completada correctamente. En cuanto finalice el reparto de gamersmafios (unos segundos) aparecerá como completada."
    redirect_to gmurl(@bet)
  end
  
  def cambiar_resultado
    require_auth_users
    @bet = Bet.find(params[:id])
    require_user_can_edit(@bet)
    raise ActiveRecord::RecordNotFound unless @bet.can_be_reopened?
    @bet.reopen
    redirect_to "/apuestas/resolve/#{@bet.id}"
  end
  
  def update_cash_for_bet
    require_auth_users
    @bet = Bet.find(params[:id])
    raise ActiveRecord::RecordNotFound if (not @bet.is_public? or @bet.closes_on < Time.now)
    err = 0
    
    # Para cada opción actualizamos el ticket correspondiente o lo creamos si no existe
    @bet.bets_options.each do |bets_option|
      ticket = bets_option.bets_tickets.find_by_user_id(@user.id)
      ticket = bets_option.bets_tickets.create({:user_id => @user.id, :ammount => 0}) if ticket.nil?
      begin
        ticket.update_ammount(params[:bet_options][bets_option.id.to_s].to_f) if params[:bet_options][bets_option.id.to_s]
      rescue TooLateToLower
        err = 1
        flash[:error] = "Solo puedes reducir tus apuestas hasta 15 minutos después de haberlas creado inicialmente"
      rescue InsufficientCash
        err = 1
        flash[:error] = "No tienes suficiente dinero"
      rescue TypeError
        err = 1
        flash[:error] = "La cantidad introducida no es válida"
      rescue AmmountTooLow
        err = 1
        flash[:error] = "La apuesta mínima por cada participante es de #{BetsTicket::MIN_BET} GMF"
      end
    end
    
    flash[:notice] = "Tu apuesta para esta partida se ha actualizado correctamente" unless err == 1
    redirect_to gmurl(@bet)
  end
  
  def new
    require_auth_users
    @title = 'Nueva apuesta'
    @pending = Bet.pending
    @bet = Bet.new
    @bet.closes_on = Time.at(Time.now().to_i + 86400 * 2)
  end
  
  def resolve
    @bet = Bet.find(params[:id])
    require_user_can_edit(@bet)
    raise ActiveRecord::RecordNotFound if (not @bet.is_public? or @bet.closes_on > Time.now or @bet.completed?)
    @title = "Completar apuesta #{@bet.title}"
    navpath2<< [@bet.title, gmurl(@bet)]
    @pending = Bet.pending
  end
  
  def aupdate
    raise "TODO"
    @bet = Bet.find(params[:id])
    require_user_can_edit(@bet)
    
    @bet.cur_editor = @user
    @bet.state = Cms::PENDING if @bet.state == Cms::DRAFT and not params[:draft].to_s == '1'
    if @bet.update_attributes(params[:bet])
      @bet.process_wysiwyg_fields
      # TODO chequeos para no guardar después de cierto tiempo
      params[:options_new].each { |s| @bet.bets_options.create({:name => s}) unless s.strip == '' } if params[:options_new]
      params[:options_delete] if params[:options_delete]
      params[:options].keys.each do |id| 
        option = @bet.bets_options.find_by_id(id.to_i)
        if option && option.name != params[:options][id]
          option.name = params[:options][id]
          option.save
        end
      end if params[:options]
      
      expire_fragment(:controller => 'home', :action => 'index', :part => 'bets')
      expire_fragment(:controller => 'home', :action => 'index', :part => "bets_#{@bet.my_faction.id}") if @bet.my_faction
      flash[:notice] = 'Encuesta actualizada correctamente.'
      if @bet.state == Cms::PENDING && params[:publish_content] == '1'
        Cms::publish_content(@bet, @user)
        flash[:notice] += "\nContenido publicado correctamente. Gracias."
      end
      if @bet.approved_by_user_id then
        redirect_to gmurl(@bet)
      else
        redirect_to :action => 'edit', :id => @bet
      end
    else
      flash[:error] = "Error al actualizar la apuesta: #{@bet.errors.full_messages_html}"
      render :action => 'edit'
    end
  end
end
