# -*- encoding : utf-8 -*-
class MiembrosController < ComunidadController
  attr_accessor :curuser
  helper :competiciones
  audit :del_firma
  before_filter :except => [ :index, :buscar, :blogs, :buscar_por_guid, :ban_request, :create_ban_request, :confirm_ban_request, :cancel_ban_request, :del_firma ] do |c|
    # /\/miembros\/([^\/]+)\/*/.match(c.params[:login])[1]
    u = User.find_by_login(c.params[:login])
    raise ActiveRecord::RecordNotFound unless u
    c.redirect_to("/miembros/#{u.login}", :status => 301) if c.params[:login] != u.login
    c.curuser = u
    c.params[:id] = u.id
  end

  def submenu
    'Ficha' if @curuser
  end

  def submenu_items
    if @curuser then
      b = gmurl(curuser)
      # blog_add = be_count > 0 ? " (#{be_count})" : ''
      base = [['Información', "#{b}"], ]
      base<< ['Hardware', "#{b}/hardware"]
      base<< ['Amigos', "#{b}/amigos"]
      base<< ['Competición', "#{b}/competicion"]
      base<< ['Estadísticas', "#{b}/estadisticas"]

      if @curuser.enable_profile_signatures?
        psigs_add = (@curuser.profile_signatures_count > 0) ? " (#{@curuser.profile_signatures_count})" : ''
        base<< ['Firmas', "#{b}/firmas"]
      end
      base
    end
  end

  def index
  end


  def member
    # Intentamos cargar por id por compatibilidad con versiones anteriores
    @title = @curuser.login
    @navpath = [['Miembros', '/miembros'], [@curuser.login, gmurl(@curuser)]]
  end
  def estadisticas
    @title = "Estadísticas de #{@curuser.login}"
    navpath2<< [@curuser.login, gmurl(@curuser)]
  end

  def amigos
    @title = "Amigos de #{@curuser.login}"
    navpath2<< [@curuser.login, gmurl(@curuser)]
  end

  def competicion
    @title = "#{@curuser.login} en competiciones"
    navpath2<< [@curuser.login, gmurl(@curuser)]
  end

  def hardware
    @title = "Hardware de #{@curuser.login}"
    navpath2<< [@curuser.login, gmurl(@curuser)]
  end

  def firmas
    raise ActiveRecord::RecordNotFound unless @curuser.enable_profile_signatures?
    @title = "Libro de firmas de #{@curuser.login}"
    navpath2<< [@curuser.login, gmurl(@curuser)]
  end

  def del_firma
    require_auth_users
    require_skill("Capo")
    ps = ProfileSignature.find(params[:id])
    raise ActiveRecord::RecordNotFound unless ps
    ps.destroy
    @js_response = "$('#ps#{ps.id}').fadeOut('normal');"
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end

  def update_signature
    raise ActiveRecord::RecordNotFound if !@curuser.enable_profile_signatures?
    if @curuser.id == @user.id || !Authorization.can_create_profile_signatures?(@user)
      raise AccessDenied
    end

    my_ps = @curuser.profile_signatures.find_by_signer_user_id(@user.id)
    if my_ps.nil?
      my_ps = @curuser.profile_signatures.new({
          :signer_user_id => @user.id,
          :user_id => @curuser.id,
      })
    end
    my_ps.signature = params[:profile_signature][:signature][0..500]
    my_ps.save # TODO filter
    redirect_to "#{gmurl(@curuser)}/firmas"
  end

  def no_tengo_amigos
    require_auth_users
    mrcheater = Ias.MrCheater
    f = Friendship.new(:sender_user_id => mrcheater.id, :receiver_user_id => @user.id)
    f.save
    flash[:notice] = "Ahora ya tienes uno :)"
    redirect_to "#{gmurl(@curuser)}/firmas"
  end

  def contenidos
    @title = @curuser.login
    navpath2<< [@curuser.login, gmurl(@curuser)]
  end

  def contenidos_tipo
    @navpath = [['Miembros', '/miembros'], [@curuser.login, gmurl(@curuser)], ['Contenidos', "#{gmurl(@curuser)}/contenidos"], [params[:content_name], "#{gmurl(@curuser)}/contenidos/#{params[:content_name]}"]]

    if params[:content_name] == 'topics' then
      params[:content_name] = 'tópics'
    end

    params[:content_name] = params[:content_name].gsub('%20', ' ')

    begin
      @c = Object.const_get(Cms::translate_content_name(params[:content_name], 0))
    rescue RuntimeError
      raise ActiveRecord::RecordNotFound
    end
  end

  def buscar
    if !params[:s] or params[:s].to_s == ''
      redirect_to '/miembros'
    else
      @navpath = [['Miembros', '/miembros'], ["Buscar #{params[:s]}", "/miembros/buscar?s=#{params[:s]}"]]
      @title = 'Resultados de la búsqueda'
      @members = User.paginate(:page => params[:page], :per_page => 50,
      :conditions => ['lower(login) like lower(?) or lower(msn) like lower(?) or lower(firstname) like lower(?) or lower(lastname) like lower(?)',
        '%' + params[:s].gsub(/[']/) { '\\'+$& } + '%',
        '%' + params[:s].gsub(/[']/) { '\\'+$& } + '%',
        '%' + params[:s].gsub(/[']/) { '\\'+$& } + '%',
        '%' + params[:s].gsub(/[']/) { '\\'+$& } + '%'],
      :order => 'lower(login) ASC')
    end
  end

  def buscar_por_guid
    if not params[:guid] or not params[:game_id]
      redirect_to '/miembros' and return
    else
      g = Game.find(params[:game_id])
      @navpath = [['Miembros', '/miembros'], ["Buscar #{params[:s]}", "/miembros/buscar?s=#{params[:s]}"]]
      @title = 'Resultados de la búsqueda'
      if not g.valid_guid?(params[:guid]) then
        flash[:error] = "El GUID introducido no es válido para el juego #{g.name}"
        @members = User.paginate(:page => params[:page], :per_page => 50, :conditions => 'id = 0') # TODO necesario para q no pete la búsqueda
      else
        @members = User.paginate(:page => params[:page], :per_page => 50,
        :conditions => "id IN (SELECT user_id FROM users_guids WHERE game_id = #{g.id} AND guid = '#{params[:guid]}')",
        :order => 'lower(login) ASC')
      end
    end
    render :action => 'buscar'
  end
end
