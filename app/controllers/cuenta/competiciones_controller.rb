class Cuenta::CompeticionesController < ApplicationController
  helper :competiciones
  
  before_filter :require_auth_users
  before_filter { |c| 
    if c.user.last_competition_id then
      begin
        c.competition = Competition.find(c.user.last_competition_id)
        raise ActiveRecord::RecordNotFound unless (c.competition.user_is_admin(c.user.id) or c.competition.user_is_participant(c.user.id))
        rescue ActiveRecord::RecordNotFound
        c.user.last_competition_id = nil
        c.competition = nil
        c.user.save
      end
    end
  }
  
  def submenu
    'MisCompeticiones'
  end
  
  def submenu_items
    l = []
    if competition && (!competition.new_record?) then
      if competition.user_is_admin(@user.id) then # TODO cache this somewhere?
        l<< ['General', '/cuenta/competiciones']
        l<< ['Configuración', '/cuenta/competiciones/configuracion']
        l<< ['Avanzada', '/cuenta/competiciones/avanzada'] if @competition.has_advanced?
        l<< ['Partidas', '/cuenta/competiciones/partidas']
        l<< ['Participantes', '/cuenta/competiciones/participantes']
        l<< ['Admins y supervisores', '/cuenta/competiciones/admins']
        l<< ['Sponsors', '/cuenta/competiciones/sponsors'] if @competition.pro?
      end
      
      if competition.user_is_participant(@user.id) then # TODO con clanes rulará?
        l<< ['Mis partidas', '/cuenta/competiciones/mis_partidas']
      end
    end
    l<< ['&raquo; Cambiar de competición', '/cuenta/competiciones/cambiar']
  end
  
  # TODO permisos
  # TODO titles
  # TODO navpaths
  # TODO views que sobren
  def index
    if @user.enable_competition_indicator
      render :action => 'warning_list'
    elsif @competition then 
      if @competition.user_is_admin(@user.id) then
        render :action => 'general'
      else
        render :action => 'mis_partidas'
      end
    else
      list
      render :action => 'list'
    end
  end
  
  def update_tourney_groups
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.has_advanced?
    # TODO chequear que son valores válidos
    @competition.competitions_types_options = @competition.competitions_types_options.merge(params.pass_sym(:tourney_groups, :tourney_winners_per_group, :tourney_rounds))
    if @competition.save
      @competition.competitions_matches.each { |m| m.destroy }
      @competition.setup_matches_tourney_classifiers
      flash[:notice] = 'Cambios guardados correctamente'
    else
      flash[:error] = "Error al guardar los cambios:<br />#{@competition.errors.full_messages_html}"
    end
    redirect_to :action => 'avanzada'
  end

  def reopen_inscriptions
    require_auth_competition_admin
    if @competition.state == 2 then
      @competition.competitions_matches.clear
      previous_stage
    else
      flash[:error] = "Imposible"
    end
  end
  
  def update_tourney_seeds
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.has_advanced?
    # TODO chequear que son valores válidos
    # cogemos el array de los participantes con sus posiciones actuales y lo
    # comparamos con el array de posiciones que nos llega. Lo que hacemos es ir
    # cambiando los participant_id de los competitions_participants para que
    # sigan el orden que nos ha llegado
    # ej:
    # participant | pos                         nuevo participant | nueva pos
    # (200) dharana       1   (1ero grupo 1)    (200) zombieke            1
    # (201) suicispai     2   (1ero grupo 2)    (201) alexkid             2
    # (202) zombieke      3   (1ero grupo 3)    (202) dharana             3
    # (203) alexkid       4   (1ero grupo 4)    (203) suicispai           4
    #
    # dharana antes era el participant_id 200
    #
    # No cambiamos la pos porque de hacerlo habría que recalcular todas las
    # partidas para que las partidas se guarden con los participant ids
    # correctos.
    #
    # Hacemos una primera pasada para evitar problemas de duplicated keys y
    # luego hacemos otro for para guardarlas.
    i = -1;
    cps = []
    cps0 = []
    data_old = {}
    
    for p in params[:participants]
      p = p[1]
      next if p[:old_participant_id] == p[:new_participant_id]
      
      # raise "going to change #{p[:old_participant_id]} with #{p[:new_participant_id]}"
      cp = @competition.competitions_participants.find(p[:old_participant_id])
      new = @competition.competitions_participants.find(p[:new_participant_id])
      
      if data_old.has_key?(new.id) # no vaya a ser que ya lo hayamos tocado en esta ocasión
        new.participant_id = data_old[new.id][:participant_id]
        new.name = data_old[new.id][:name]
      end
      
      data_old[cp.id] = { :participant_id => cp.participant_id, :name => cp.name, :roster => cp.roster, :created_on => cp.created_on }
      cp.participant_id = i;
      cp.name = i;
      raise cp.errors.full_messages.join("\n") unless cp.save
      
      cp.participant_id = new.participant_id
      cp.name = new.name
      cp.roster = new.roster
      cp.created_on = new.created_on
      # raise "new participant_id: #{cp.participant_id} | new name: #{cp.name}"
      # break
      cps<< cp
      i -= 1
    end
    
    cps.each { |cp| raise cp.errors.full_messages.join("\n") unless cp.save }
    
    flash[:notice] = 'Cambios guardados correctamente'
    redirect_to :action => 'avanzada'
  end
  
  # TODO temp temp
  def add_participants
    require_auth_competition_admin
    if @competition.competitions_participants_type_id == 1 then
      params[:participants_count].to_i.times do |time|
        u = User.find(:first, :order => 'RANDOM() ASC') # TODO puede haber duplicados
        
        # TODO no limpio, copypasted
        @competition.competitions_participants.create({:participant_id => u.id, :name => u.login, :competitions_participants_type_id => @competition.competitions_participants_type_id})
      end
    else # clanes
      params[:participants_count].to_i.times do |time|
        c = Clan.find(:first, :order => 'RANDOM() ASC') # TODO puede haber duplicados
        
        # TODO no limpio, copypasted
        @competition.competitions_participants.create({:participant_id => c.id, :name => c.tag, :competitions_participants_type_id => @competition.competitions_participants_type_id})
      end
    end
    redirect_to '/cuenta/competiciones'
  end
  
  def recreate_matches
    require_auth_competition_admin
    raise AccessDenied unless @competition.can_recreate_matches?
    @competition.recreate_matches
    @competition.state = 3
    @competition.save
    redirect_to '/cuenta/competiciones/partidas'
  end
  
  def remove_all_participants
    require_auth_competition_admin
    @competition.competitions_participants.clear
    redirect_to '/cuenta/competiciones'
  end
  
  def reselect_maps
    require_auth_competition_admin
    for cm in @competition.competitions_matches
      cm.competitions_matches_games_maps.clear
    end
    @competition.setup_maps_for_matches
    redirect_to '/cuenta/competiciones'
  end
  
  def update_matches_games_maps
    require_auth_competition_admin
    raise AccessDenied unless @competition.default_maps_per_match
    params[:competitions_matches] ||= []
    n = 0
    params[:competitions_matches].each do |cm_id|
      # default_maps_per_match no se cambia después de crear las partidas así que sabemos que coinciden
      m = @competition.competitions_matches.find(cm_id)
      i = 0
      m.competitions_matches_games_maps.each do |rel_map|
        if params[:new_maps][i].to_s != ''
          rel_map.games_map_id = params[:new_maps][i]
          rel_map.save
        end
        i += 1
      end
      
      # por si acaso falta alguno
      if i < @competition.default_maps_per_match
       (@competition.default_maps_per_match - i).times do |times_more|
          m.competitions_matches_games_maps.create({:games_map_id => params[:new_maps][(i + times_more)]})
        end
      end
      
      n += 1
    end
    flash[:notice] =  "<strong>#{n}</strong> partidas actualizadas correctamente."
    redirect_to '/cuenta/competiciones/partidas'
  end
  
  def update_matches_play_on
    require_auth_competition_admin
    params[:competitions_matches] ||= []
    i = 0
    params[:competitions_matches].each do |cm_id|
      m = @competition.competitions_matches.find(cm_id)
      m.play_on = select_datetime_to_time(params[:matches], :play_on)
      m.save
      i += 1
      # TODO notificar usuarios?
    end
    flash[:notice] =  "<strong>#{i}</strong> partidas actualizadas correctamente."
    redirect_to '/cuenta/competiciones/partidas'
  end
  
  def previous_stage
    require_auth_competition_admin
    @competition.state -= 1
    if @competition.state < 0 then
      @competition.state = 0
    end
    @competition.save
    flash[:notice] = "Viaje en el tiempo efectuado correctamente."
    redirect_to '/cuenta/competiciones'
  end
  # end TODO
  
  def general
    require_auth_competition_admin
  end
  
  def avanzada
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.has_advanced?
  end
  
  def add_participant
    require_auth_competition_admin
    raise "Imposible" unless @competition.can_add_participants?
    if @competition.competitions_participants_type_id == Competition::CLANS
      new_p_real = Clan.find_by_name(params[:participant_hid])
    else
      new_p_real = User.find_by_login(params[:participant_hid])
    end
    
    if new_p_real
      participant = @competition.add_participant(new_p_real)
      flash[:notice] = 'Participante añadido correctamente' # TODO enviar email de que ha sido invitado
    else
      flash[:error] = "No se ha encontrado al #{@competition.competitions_participants_type_id == Competition::USERS ? 'usuario' : 'clan'} <strong>#{params[:participant_hid]}</strong>"
    end
    redirect_to '/cuenta/competiciones/participantes'
  end
  
  def add_allowed_participant
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.can_modify_allowed_participants?
    if @competition.competitions_participants_type_id == Competition::CLANS
      new_p_real = Clan.find_by_name(params[:participant_hid])
    else
      new_p_real = User.find_by_login(params[:participant_hid])
    end
    
    if new_p_real
      participant = @competition.allowed_competitions_participants.create({:participant_id => new_p_real.id})
      flash[:notice] = 'Participante invitado correctamente' # TODO enviar email de que ha sido invitado
      if @competition.state == 3 then
        #        if @competition.competitions_participants_type_id == Competition::CLANS
        #          new_p_real.admins.each { |admin| Notification.deliver_invitedparticipant(admin, {:competition => @competition}) }
        #        else
        #          Notification.deliver_invitedparticipant(new_p_real, {:competition => @competition})
        #        end
        #        TODO enviar email al comenzar competición
      end
    else
      flash[:error] = "No se ha encontrado al participante #{participant_hid}"
    end
    redirect_to '/cuenta/competiciones/participantes'   
  end
  
  def configuracion
    require_auth_competition_admin
    raise AccessDenied if @competition.state == 4
  end
  
  def admins
    require_auth_competition_admin
  end
  
  def partidas
    require_auth_competition_admin
  end
  
  def participantes
    require_auth_competition_admin
  end
  
  def eliminar_participante
    require_auth_competition_admin
    # TODO almost copypasted de controllers/competiciones_controller
    if @competition.competitions_participants.find_by_id(params[:id]) && @competition.can_delete_participants?
      p = @competition.competitions_participants.find(params[:id])
      Bank.transfer(@competition, p.the_real_thing, @competition.fee, "Devolución de inscripción en #{@competition.name}") if @competition.fee?
      p.destroy
      flash[:notice] = 'Participante eliminado correctamente.'
    end
    redirect_to '/cuenta/competiciones/participantes'
  end
  
  def crear_admin 
    require_auth_competition_admin
    u = User.find_by_login(params[:login])
    if u
      @competition.add_admin(u)
      flash[:notice] = 'Admin creado correctamente'
    else
      flash[:error] = "No se ha encontrado ningún usuario con el login #{params[:login]}"
    end
    redirect_to '/cuenta/competiciones/admins'
  end
  
  def eliminar_admin
    require_auth_competition_admin
    @competition.del_admin(User.find(params[:user_id]))
    redirect_to '/cuenta/competiciones/admins'
  end
  
  
  def crear_supervisor 
    require_auth_competition_admin
    u = User.find_by_login(params[:login])
    if u
      @competition.add_supervisor(u)
      flash[:notice] = 'Supervisor creado correctamente'
    else
      flash[:error] = "No se ha encontrado ningún usuario con el login #{params[:login]}"
    end
    redirect_to '/cuenta/competiciones/admins'
  end
  
  def eliminar_supervisor
    require_auth_competition_admin
    @competition.del_supervisor(User.find(params[:user_id]))
    redirect_to '/cuenta/competiciones/admins'
  end
  
  def cambiar
  end
  
  def mis_partidas
    require_auth_competition_participant
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
  :redirect_to => { :action => :list }
  
  def list
    if @competition then 
      if @competition.user_is_admin(@user.id) then
        render :action => 'general'
      else
        render :action => 'mis_partidas'
      end
    end
  end
  
  def new
    @title = 'Crear nueva competición'
    @navpath = [['Cuenta', '/cuenta'], ['Competiciones', '/cuenta/competiciones'], ['Nueva', '/cuenta/competiciones/new']]
    @competition = Competition.new
  end
  
  def create
    params[:competition][:pro] = false unless @user.is_superadmin
    raise ActiveRecord::RecordNotFound unless (%w(Ladder Tournament League).include?(params[:competition][:type]))
    params[:competition][:competitions_types_options] = HashWithIndifferentAccess.new
    params[:competition][:timetable_options] = HashWithIndifferentAccess.new
    cls = ActiveSupport::Inflector::constantize(params[:competition][:type])
    @competition = cls.new(params[:competition].pass_sym(:name, :pro, :game_id, :competitions_participants_type_id, :competitions_types_options, :timetable_options))
    if @competition.save
      @user.last_competition_id = @competition.id
      @user.save
      @competition.add_admin(@user)
      flash[:notice] = 'Competición creada correctamente.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end
  
  def update
    require_auth_competition_admin
    
    @competition = Competition.find(params[:id])
    if @competition.state < 3 then
      params[:competition] = params[:competition].block_sym(:pro, :game_id, :type, :competitions_participants_type_id)
      if params[:competition][:allowed_competitions_participants] then
        @competition.allowed_competitions_participants.clear
        for p in params[:competition][:allowed_competitions_participants].strip.split("\n")
          case @competition.competitions_participants_type_id
            when 1:
            u = User.find_by_login(p.strip)
            @competition.allowed_competitions_participants.create({:participant_id => u.id}) if u
            when 2:
            c = Clan.find_by_name(p.strip)
            @competition.allowed_competitions_participants.create({:participant_id => c.id})
          end
        end
        params[:competition].delete('allowed_competitions_participants')
      end
    elsif @competition.state < 4 then
      params[:competition] = params[:competition].pass_sym(:description, :rules, :games_map_ids, :header_image)
    end
    
    if @competition.update_attributes(params[:competition])
      flash[:notice] = 'Competición actualizada correctamente.'
      redirect_to :action => 'configuracion'
    else
      render :action => 'configuracion'
    end
  end
  
  def destroy
    @competition = Competition.find(@user.last_competition_id)
    require_auth_competition_admin
    raise AccessDenied unless @competition.state < 3
    @competition.destroy
    flash[:notice] = 'Competición borrada correctamente'
    redirect_to :action => 'cambiar'
  end
  
  def change_state
    if @competition.switch_to_state(params[:new_state_id].to_i) then
      flash[:notice] = 'La competición ha avanzado a la siguiente fase.'
    else
      flash[:error] = 'No se puede avanzar a la siguiente fase.'
    end
    
    redirect_to :action => 'general', :id => @competition.id
  end
  
  def switch_active_competition
    @user.last_competition_id = params[:id]
    @user.save
    if @user.enable_competition_indicator
      c = Competition.find(@user.last_competition_id)
      if c.user_is_admin(@user.id)
        redirect_to '/cuenta/competiciones/configuracion'
      else
        redirect_to '/cuenta/competiciones/mis_partidas'
      end
    else
      redirect_to '/cuenta/competiciones'
    end
  end
  
  def require_auth_competition_admin
    raise AccessDenied unless @competition && (@competition.user_is_admin(@user.id) || @user.is_superadmin?)
  end
  
  def require_auth_competition_participant
    raise AccessDenied unless @competition && @competition.user_is_participant(@user.id)
  end
  
  
  
  def sponsors
    sponsors_list
    render :action => 'sponsors_list'
  end
  
  def sponsors_list
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.pro?
    @title = 'Sponsors'
    @navpath = [['Mis clanes', '/cuenta/competiciones'], ['Sponsors', '/cuenta/competiciones/sponsors']]
    @competitions_sponsor_pages, @competitions_sponsors = paginate :competitions_sponsors, :conditions => ['competition_id = ?', @competition.id], :per_page => 10
  end
  
  def sponsors_new
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.pro?
    @title = 'Nuevo sponsor'
    @navpath = [['Mis clanes', '/cuenta/competiciones'], ['Sponsors', '/cuenta/competiciones/sponsors'], ['Nuevo', '/cuenta/competiciones/sponsors_new']]
    @competitions_sponsor = CompetitionsSponsor.new
  end
  
  def sponsors_create
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.pro?
    params[:competitions_sponsor][:competition_id] = @competition.id
    
    @competitions_sponsor = CompetitionsSponsor.new(params[:competitions_sponsor])
    if @competitions_sponsor.save
      flash[:notice] = 'Sponsor creado correctamente.'
      redirect_to :action => 'sponsors_list'
    else
      render :action => 'sponsors_new'
    end
  end
  
  def sponsors_edit
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.pro?
    @competitions_sponsor = CompetitionsSponsor.find_or_404(:first, :conditions => ['id = ? and competition_id = ?', params[:id], @competition.id])
    @title = 'Nuevo sponsor'
    @navpath = [['Mis clanes', '/cuenta/competiciones'], ['Sponsors', '/cuenta/competiciones/sponsors'], ['Nuevo', "/cuenta/competiciones/sponsors_edit/#{@competitions_sponsor.id}"]]
  end
  
  def sponsors_update
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.pro?
    @competitions_sponsor = CompetitionsSponsor.find_or_404(:first, :conditions => ['id = ? and competition_id = ?', params[:id], @competition.id])
    if @competitions_sponsor.update_attributes(params[:competitions_sponsor])
      flash[:notice] = 'Sponsor actualizado correctamente.'
      redirect_to :action => 'sponsors_edit', :id => @competitions_sponsor
    else
      render :action => 'sponsors_edit'
    end
  end
  
  def sponsors_destroy
    require_auth_competition_admin
    raise ActiveRecord::RecordNotFound unless @competition.pro?
    CompetitionsSponsor.find_or_404(:first, :conditions => ['id = ? and competition_id = ?', params[:id], @competition.id]).destroy
    flash[:notice] = 'Sponsor borrado correctamente.'
    redirect_to :action => 'sponsors_list'
  end
  
  def select_datetime_to_time(parent,field)
    t={}
    parent.keys.map{|k| k.to_s}.grep(/^#{field}\(.+\)$/).each do |k|
      k=~/^#{field}\((.+)\)$/
      case $1
        when '1i'
        f = :year
        when '5i'
        f = :minute
        when '4i'
        f = :hour
        when '3i'
        f = :day
        when '2i'
        f = :month
      end
      t[f]=parent[k.to_sym].to_i
    end
    Time.gm(t[:year],t[:month],t[:day],t[:hour],t[:minute])
  end
end
