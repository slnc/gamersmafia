class Admin::UsuariosController < ApplicationController
  before_filter :require_auth_admins, :except => [ :edit, :index, :clear_photo, :clear_description, :report, :ban_request, :create_unban_request, :confirm_unban_request, :create_ban_request, :confirm_ban_request, :cancel_ban_request, :confirmar_ban_request , :set_antiflood_level]
  before_filter :only => [ :index, :clear_photo, :clear_description, :ban_request, :create_unban_request, :confirm_unban_request, :create_ban_request, :confirm_ban_request, :cancel_ban_request ] do |c|
    raise AccessDenied unless c.user && c.user.has_admin_permission?(:capo)
  end
  before_filter :only => [ :confirmar_ban_request ] do |c|
    raise AccessDenied unless c.user && (c.user.has_admin_permission?(:capo) || c.user.is_hq?)
  end
  before_filter :only => [ :report, :set_antiflood_level ] do |c|
    raise AccessDenied unless c.user && c.user.is_hq?
  end
  verify :method => :post, :only => [ :update, :check_karma, :check_faith, :check_registered_on ], :redirect_to => '/admin/usuarios'
  # gm_options :submenu => 'admin', :submenu_items => admin_menu_items, :global_pos => 'admin'
  
  def wmenu_pos
    'hq'
  end
  
  def index
    if params[:s]
      params[:s].strip!
      @user_pages, @users = paginate :user, :per_page => 20, :order_by =>'char_length(login) asc, lower(login) asc', 
      :conditions => ['lower(login) like lower(?) or lower(email) like lower(?) or lower(firstname) like lower(?) or lower(lastname) like lower(?) or ipaddr LIKE ?', 
				'%' + params[:s].gsub(/[']/) { '\\'+$& } + '%',
				'%' + params[:s].gsub(/[']/) { '\\'+$& } + '%',
				'%' + params[:s].gsub(/[']/) { '\\'+$& } + '%',
				'%' + params[:s].gsub(/[']/) { '\\'+$& } + '%',
        '%' + params[:s].gsub(/[']/) { '\\'+$& } + '%']
    elsif params[:sm]
      smc = {}
      smc[:confirmed] = "state <> #{User::ST_UNCONFIRMED}"
      smc[:unconfirmed] = "state = #{User::ST_UNCONFIRMED}"
      smc[:active] = "state = #{User::ST_ACTIVE}"
      smc[:banned] = "state = #{User::ST_BANNED}"
      smc[:disabled] = "state = #{User::ST_DISABLED}"
      smc[:zombies] = "state = #{User::ST_ZOMBIE}"
      smc[:antiflood] = "state <> #{User::ST_UNCONFIRMED} and antiflood_level > -1"
      
      @user_pages, @users = paginate :user, :conditions => smc.fetch(params[:sm].to_sym), :per_page => 20, :order_by =>'id desc'
    else
      @user_pages, @users = paginate :user, :per_page => 20, :order_by =>'id desc'
    end
  end
  
  def destroy
    @edituser = User.find_or_404(:first, :conditions => ['id = ? and is_superadmin is false', params[:id]])
    flash[:notice] = "Usuario #{@edituser.login} borrado correctamente." if @edituser.destroy
    redirect_to '/admin/usuarios'
  end
  
  def ban
    @edituser = User.find_or_404(:first, :conditions => ['id = ? and is_superadmin is false', params[:id]])
    @edituser.change_internal_state 'banned'
    IpBan.create({:user_id => @user.id, :ip => @edituser.ipaddr, :comment => "Ban al usuario #{@edituser.login}", :expires_on => 7.days.since})
    flash[:notice] = "Usuario <strong>#{@edituser.login}</strong> baneado. Ip <strong>#{@edituser.ipaddr}</strong> baneada para nuevos registros durante 7 días."
    redirect_to '/admin/usuarios'
  end
  
  def edit
    @edituser = User.find(params[:id])
    @title = "Editar usuario #{@edituser.login}"
  end
  
  def update
    u = User.find(params[:id])
    
    if params[:edituser][:faction_id].to_s != u.faction_id.to_s
      Factions::user_joins_faction(u, params[:edituser][:faction_id])
      expire_fragment('/home/index/factions') # TODO esto no debería hacerse aquí
    end
    
    if params[:users_role] && params[:users_role][:role].to_s != '' # añadir rol
      u.users_roles<< UsersRole.create(:role => params[:users_role][:role], :role_data => params[:users_role][:role_data])
    end
    
    u.update_admin_permissions(params[:edituser][:admin_permissions]) if params[:edituser][:admin_permissions].to_s != '' 
    if u.update_attributes(params[:edituser].pass_sym(:firstname, :lastname, :login, :antiflood_level, :state, :password, :password_confirmation, :email, :is_hq))
      flash[:notice] = 'Cambios guardados correctamente.'
      redirect_to :action => 'edit', :id => u.id
    else
      flash[:error] = u.errors.full_messages.join(',')
      render :action => 'edit'
    end
  end
  
  def users_role_destroy
    UsersRole.find(params[:id]).destroy
    render :nothing => true
  end
  
  def check_registered_on
    # trata de buscar la fecha de registro más cercana a la que el usuario
    # empezó a participar
    u = User.find(params[:id])
    first_activity = u.first_activity
    
    if first_activity < u.created_on then
      u.created_on = first_activity
      u.save
      @edituser = u
      render :layout => false, :action => 'check_registered_on_fixed'
    else
      render :layout => false, :action => 'check_registered_on_ok'
    end
  end
  
  def check_karma
    u = User.find(params[:id])
    kp = u.karma_points
    u.cache_karma_points = nil
    u.save
    kp2 = u.karma_points
    @edituser = u
    
    if kp != kp2 then
      @kp_previous = kp
      @kp_correct = kp2
      render :layout => false, :action => 'check_karma_fixed'
    else
      render :layout => false, :action => 'check_karma_ok'
    end
  end
  
  def check_faith
    u = User.find(params[:id])
    fp = u.faith_points
    u.cache_faith_points = nil
    u.save
    fp2 = u.faith_points
    @edituser = u
    
    if fp != fp2 then
      @fp_previous = fp
      @fp_correct = fp2
      render :layout => false, :action => 'check_faith_fixed'
    else
      render :layout => false, :action => 'check_faith_ok'
    end
  end
  
  def check_gmf
    u = User.find(params[:id])
    @edituser = u
    cash = u.cash
    cash2 = Bank.cash(u)
    
    if cash != cash2 then
      User.db_query("UPDATE users SET cash = #{cash2} WHERE id = #{u.id}")
      @edituser.reload
      @cash_previous = cash
      @cash_correct = cash2
      render :layout => false, :action => 'check_gmf_fixed'
    else
      render :layout => false, :action => 'check_gmf_ok'
    end
  end
  
  def del_comments
    params[:comments].each { |c_id| Comment.find(c_id.to_i).mark_as_deleted }
    flash[:notice] = "Comentarios borrados correctamente"
    redirect_to "/admin/usuarios/edit/#{params[:user_id]}#comments"
  end
  
  def reset_avatar
    u = User.find(params[:id])
    u.change_avatar
    redirect_to "/admin/usuarios/edit/#{params[:id]}"
  end
  
  
  def ban_request
    u = User.find_by_login(params[:login])
    raise ActiveRecord::RecordNotFound unless u
    @title = "Banear a #{u.login}"
  end
  
  def confirmar_ban_request
    # raise AccessDenied unless @user && @user.has_admin_permission?(:capo)
    @br = BanRequest.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @br
    @title = "Ban #{@br.id}"
  end
  
  def create_ban_request
    u = User.find_by_login(params[:login])
    raise ActiveRecord::RecordNotFound unless u && @user.has_admin_permission?(:capo) && params[:login]
    b = BanRequest.new({:user_id => @user.id, :banned_user_id => u.id, :reason => params[:reason]})
    if b.save
      flash[:notice] = "Ban creado correctamente."
    else
      flash[:error] = "Error al crear el ban: #{b.errors.full_messages_html}"
    end
    redirect_to gmurl(u)
  end
  
  def create_unban_request
    u = User.find_by_login(params[:login])
    raise ActiveRecord::RecordNotFound unless u && @user.has_admin_permission?(:capo) && params[:login]
    b = BanRequest.find(:first, :conditions => ['banned_user_id = ? and confirmed_on is not null', u.id], :order => 'confirmed_on DESC')
    
    if b.update_attributes({:unban_user_id => @user.id, :reason_unban => params[:reason_unban]})
      flash[:notice] = "Unban iniciado correctamente."
    else
      flash[:error] = "Error al iniciar el unban: #{b.errors.full_messages_html}"
    end
    redirect_to gmurl(u)
  end
  
  def confirm_ban_request
    br = BanRequest.find(:first, :conditions => ['id = ? and user_id <> ? and confirming_user_id is null', params[:id], @user.id])
    raise ActiveRecord::RecordNotFound unless br
    if br.confirm(@user.id)
      flash[:notice ] = "El ban ha sido confirmado correctamente. Usuario <strong>#{br.banned_user.login}</strong> baneado."
    else
      flash[:error] = "Error al confirmar el ban: #{br.errors.full_messages_html}."
    end
    redirect_to "/site/slog"
  end
  
  def confirm_unban_request
    br = BanRequest.find(:first, :conditions => ['id = ? and unban_user_id <> ? and unban_confirming_user_id is null', params[:id], @user.id])
    raise ActiveRecord::RecordNotFound unless br
    if br.confirm_unban(@user.id)
      flash[:notice ] = "El usuario <strong>#{br.banned_user.login}</strong> ha sido desbaneado correctamente."
    else
      flash[:error] = "Error al confirmar el desbaneo: #{br.errors.full_messages_html}."
    end
    redirect_to "/site/slog"
  end
  
  def cancel_ban_request    
    br = BanRequest.find(:first, :conditions => ['id = ? and user_id = ? and confirming_user_id is null', params[:id], @user.id])
    raise ActiveRecord::RecordNotFound unless br
    if br.destroy
      flash[:notice ] = "El ban ha sido cancelado correctamente."
    else
      flash[:error] = "Error al destruir el ban: #{br.errors.full_messages_html}."
    end
    redirect_to "/site/slog"
  end
  
  def send_hq_invitation
    recipient = User.find(params[:id])
    raise ActiveRecord::RecordNotFound unless recipient
    m = Message.new(:sender => User.find(1), :recipient => recipient, :title => 'Invitación para formar parte del HQ', :message => "Buenas #{recipient.login},

¿Te gustaría formar parte del HQ? El HQ son un conjunto de usuarios de gamersmafia con acceso a la zona de gestión de bugs e ideas y al wiki interno de la web. Aparte de esas zonas especiales también tenemos una lista de correo interna donde se anuncian ideas, los detalles de las actualizaciones de la web y otros temas.

Lo único que es necesario para formar parte del HQ son ganas de mejorar la comunidad y la web y un mínimo de participación en al menos una de las áreas como la lista de correo.

¿Qué me dices? Si te interesa respóndeme con un email en el que quieras recibir los correos de la lista interna. Es importante que la dirección no sea hotmail porque con hotmail es imposible seguir una lista de correo. Cuentas como @gmail o cuentas que no sean webmail sí que sirven. Si quieres tener una cuenta tunick@gamersmafia.com también te la puedo crear.

Quedo a la espera de tu respuesta :)")
    if m.save
      flash[:notice] = "Invitación enviada correctamente"
    else
      flash[:error] = "Error al enviar el mensaje"
    end
    redirect_to "/admin/usuarios/edit/#{params[:id]}"
  end
  
  def set_antiflood_level
    # raise AccessDenied unless user_is_authed && @user.has_admin_permission?(:capo)
    u = User.find(params[:user_id])
    # TODO user.rb debería decir si el valor está bien o no
    if params[:antiflood_level].to_i < -1 or params[:antiflood_level].to_i > 5 then
      params[:antiflood_level] = '0'
    end
    if @user.has_admin_permission?(:capo)
      SlogEntry.create(:type_id => SlogEntry::TYPES[:emergency_antiflood], :reporter_user_id => @user.id, :headline => "Antiflood #{User::ANTIFLOOD_LEVELS[u.antiflood_level]} impuesto a <strong><a href=\"#{gmurl(u)}\">#{u.login}</a></strong> por <a href=\"#{gmurl(@user)}\">#{@user.login}</a>")
    else
      SlogEntry.create(:type_id => SlogEntry::TYPES[:emergency_antiflood], :reporter_user_id => @user.id, :headline => "Antiflood de emergencia impuesto a <strong><a href=\"#{gmurl(u)}\">#{u.login}</a></strong> por <a href=\"#{gmurl(@user)}\">#{@user.login}</a>")
    end
    u.antiflood_level = params[:antiflood_level]
    u.save
    redirect_to gmurl(u)
  end
  
  def clear_description
    u = User.find(params[:id])
    u.description = nil
    flash[:notice] = "Descripción borrada correctamente."    
    u.save
    redirect_to gmurl(u)
  end
  
  def clear_photo
    u = User.find(params[:id])
    User.db_query("UPDATE users SET photo = null where id = #{u.id}")
    flash[:notice] = "Foto borrada correctamente."
    #u.photo = nil
    #u.save
    redirect_to gmurl(u)
  end
  
  def report
    @curuser = User.find(params[:id])
    if @user.is_hq?
      reason_str = (params[:reason] && params[:reason].to_s != '' && params[:reason].to_s != 'Razón..') ? " (#{params[:reason]})" : '' 

      sl = SlogEntry.create({:type_id => SlogEntry::TYPES[:user_report], :reporter_user_id => @user.id, :headline => "Perfil de <strong><a href=\"#{gmurl(@curuser)}\">#{@curuser.login}</a></strong> reportado #{reason_str} por <a href=\"#{gmurl(@user)}\">#{@user.login}</a>"})
      if sl.new_record?
        flash[:error] = "Error al reportar al usuario:<br />#{sl.errors.full_messages_html}"
      else
        flash[:notice] = "Usuario reportado correctamente"
      end
      render :partial => '/shared/ajax_facebox_feedback', :layout => false
    else
      raise AccessDenied
    end
  end
end
