class Admin::ContenidosController < ApplicationController
  before_filter :require_auth_users
  
  #def wmenu_pos
  #  'admin'
  #end
  
  def submenu
    return 'Contenidos'
  end
  
  def submenu_items
    if @user.is_bigboss? then
      return [['Hotmap', '/admin/contenidos/hotmap'], ['Pendientes', '/admin/contenidos'], ['Últimas decisiones', '/admin/contenidos/ultimas_decisiones'], ['Papelera', '/admin/contenidos/papelera'], ]
    elsif @user.is_editor? then
      return [['Pendientes', '/admin/contenidos'], ['Papelera', '/admin/contenidos/papelera'], ]
    else
      return [['Pendientes', '/admin/contenidos'], ]
    end
  end
  
  def index
    @title = 'Contenidos pendientes de moderar'
    @contents = []
    # Content.find(:all, :conditions => "state = #{Cms::PENDING} AND content_type_id IN (
    for c in Cms::contents_classes_publishable
      controller = Cms::translate_content_name(c.name)
      @contents<< [Cms::translate_content_name(c.name).capitalize, c.pending, controller]
    end
  end
  
  def papelera
    require_user_is_staff
    params[:portal] = self.portal.code if params[:portal].nil? && self.portal.id != -1 && self.portal.type == 'FactionsPortal'
    
    if params[:portal].to_s != '' then
      b = FactionsPortal.find_by_code(params[:portal])
    else
      b = GmPortal.new
    end
    @title = 'Contenidos en la papelera'
    @contents = []
    for c in Cms::contents_classes_publishable + [Topic]
      @contents<< [Cms::translate_content_name(c.name).capitalize, b.send(ActiveSupport::Inflector::underscore(c.name)).find(:deleted, :conditions => 'contents.updated_on > now() - \'1 month\'::interval'), Cms::translate_content_name(c.name)]
    end
  end
  
  def ultimas_decisiones
    @title = 'Últimas decisiones'
    require_user_is_staff
  end
  
  def hotmap
    @title = 'Hotmap'
    require_user_is_staff
  end
  
  def recover
    content = Content.find(params[:id])
    obj = content.real_content
    require_user_can_edit(obj)
    obj.recover(@user)
    render :nothing => true
  end
  
  def change_authorship
    obj = Content.find(params[:content_id])
    obj = obj.real_content
    require_user_can_edit(obj)
    new_author = User.find_by_login(params[:login])
    if new_author
      obj.change_authorship(new_author, @user)
      flash[:notice] = 'Autoría cambiada correctamente'
    else
      flash[:error] = "No se ha encontrado al usuario '#{params[:login]}'"
    end
    redirect_to (params[:redirto] || '/')
  end
  
  def mass_moderate
    if params[:items] then
      params[:deny_reason] = params[:deny_reason_other] if params[:deny_reason] == 'Otra'
      for k in params[:items]
        content = Content.find(k.to_i)
        obj = content.real_content
        require_user_can_edit(obj)
        
        # TODO borrar caches de portada
        if params[:mass_action] == 'publish' then
          Cms::publish_content(obj, @user)
        elsif params[:mass_action] == 'deny' then
          Cms::deny_content(obj, @user, params[:deny_reason])
        end
      end
    end
    
    redirect_to '/admin/contenidos'
  end
  
  def switch_decision
    # TODO this is not a switch, it-s one way
    pd = PublishingDecision.find(params[:id], :include => :content)
    require_user_can_edit pd.content.real_content
    Cms::publish_content(pd.content.real_content, pd.user)
    redirect_to url_for_content_onlyurl(pd.content.real_content).gsub('show', 'edit')
  end
  
  def publish_content
    Cms::publish_content(Content.find(params[:id]).real_content, @user, params[:accept_comment])
    flash[:notice] = 'Tu voto se ha contabilizado correctamente. Gracias'
    redirect_to '/admin/contenidos'
  end
  
  def deny_content
    params[:deny_reason] = params[:deny_reason_other] if params[:deny_reason] == 'Otra'
    if params[:deny_reason].to_s == ''
      flash[:error] = 'Debes especificar una razón para denegar el contenido'
    else
      Cms::deny_content(Content.find(params[:id]).real_content, @user, params[:deny_reason])
      flash[:notice] = 'Tu voto se ha contabilizado correctamente. Gracias'
    end
    redirect_to '/admin/contenidos'
  end
  
  def report
    @content = Content.find(params[:id])
    if @user.is_hq?
      ttype, scope = SlogEntry.fill_ttype_and_scope_for_content_report(@content)
      sl = SlogEntry.create({:scope => scope, :type_id => ttype, :reporter_user_id => @user.id, :headline => "#{Cms.faction_favicon(@content.real_content)}<strong><a href=\"#{url_for_content_onlyurl(@content.real_content)}\">#{@content.id}</a></strong> reportado (#{params[:reason]}) por <a href=\"#{gmurl(@user)}\">#{@user.login}</a>"})
      if sl.new_record?
        flash[:error] = "Error al reportar el contenido:<br />#{sl.errors.full_messages_html}"
      else
        flash[:notice] = "Contenido reportado correctamente"
      end
      render :partial => '/shared/ajax_facebox_feedback', :layout => false
      # render :partial => '/shared/ajax_feedback', :layout => false
    else
      raise AccessDenied
    end
  end
end
