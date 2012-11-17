# -*- encoding : utf-8 -*-
class Admin::ContenidosController < ApplicationController
  before_filter :require_auth_users, :except => [ :show ]

  def submenu
    'Contenidos'
  end

  def submenu_items
    # TODO(slnc): adapt to new skills system
    if @user.is_bigboss?
      return [
          ['Hotmap', '/admin/contenidos/hotmap'],
          ['Pendientes', '/admin/contenidos'],
          ['Huérfanos', '/admin/contenidos/huerfanos'],
          ['Papelera', '/admin/contenidos/papelera'], ]
    elsif @user.is_editor?
      return [
          ['Pendientes', '/admin/contenidos'],
          ['Huérfanos', '/admin/contenidos/huerfanos'],
          ['Papelera', '/admin/contenidos/papelera'], ]
    else
      return [['Pendientes', '/admin/contenidos'], ]
    end
  end

  def index
    raise AccessDenied unless Authorization.can_access_moderation_queue?(@user)
    @title = 'Contenidos pendientes de moderar'
    @contents = []

    for c in Cms::contents_classes_publishable
      controller = Cms::translate_content_name(c.name)
      @contents << [
          Cms::translate_content_name(c.name).capitalize,
          c.pending,
          controller]
    end
  end

  def huerfanos
    require_user_is_staff
  end

  def papelera
    raise AccessDenied unless Authorization.can_delete_contents?(@user)
    if (params[:portal].nil? &&
        self.portal.id != -1 &&
        self.portal.type == 'FactionsPortal')
      params[:portal] = self.portal.code
    end

    if params[:portal].to_s != '' then
      b = FactionsPortal.find_by_code(params[:portal])
    else
      b = GmPortal.new
    end
    @title = 'Contenidos en la papelera'
    @contents = []
    for c in Cms::contents_classes_publishable + [Topic]
    end
      @contents << [
          Cms::translate_content_name(c.name).capitalize,
          b.send(ActiveSupport::Inflector::underscore(c.name)).find(
              :deleted,
              :conditions => 'contents.updated_on > now() - \'1 month\'::interval'),
          Cms::translate_content_name(c.name)]
  end

  def hotmap
    @title = 'Hotmap'
    require_user_is_staff
  end

  def recover
    obj = Content.find(params[:id]).real_content
    require_user_can_edit(obj)
    obj.recover(@user)
    @js_response = (
        "$('#content#{obj.unique_content_id}').fadeOut('normal');")
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end

  def change_authorship
    obj = Content.find(params[:content_id]).real_content
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
    raise AccessDenied unless Authorization.can_mass_moderate_contents?(@user)

    if params[:items] then
      if (params[:deny_reason] == 'Otra')
        params[:deny_reason] = params[:deny_reason_other]
      end

      for k in params[:items]
        content = Content.find(k.to_i)
        obj = content.real_content

        # TODO borrar caches de portada
        if params[:mass_action] == 'publish' then
          Content.publish_content_directly(obj, @user)
        elsif params[:mass_action] == 'deny' then
          Content.deny_content_directly(obj, @user, params[:deny_reason])
        end
      end
    end

    redirect_to '/admin/contenidos'
  end

  def report
    raise AccessDenied unless Authorization.can_report_contents?(@user)
    @content = Content.find(params[:id])

    ttype, scope = Alert.fill_ttype_and_scope_for_content_report(@content)
    sl = Alert.create({
        :scope => scope,
        :type_id => ttype,
        :reporter_user_id => @user.id,
        :headline => (
            "#{Cms.faction_favicon(@content.real_content)}<strong>"+
            "<a href=\"#{Routing.url_for_content_onlyurl(@content.real_content)}\">"+
            "#{@content.id}</a></strong> reportado (#{params[:reason]}) "+
            "por <a href=\"#{gmurl(@user)}\">#{@user.login}</a>"),
    })

    if sl.new_record?
      flash[:error] = "Error al reportar el contenido:"+
                      "<br />#{sl.errors.full_messages_html}"
    else
      flash[:notice] = "Contenido reportado correctamente"
    end
    render :partial => '/shared/ajax_facebox_feedback', :layout => false
  end

  def close
    params[:reason] = nil if params[:reason] && params[:reason] == 'Razón...'
    @content = Content.find(params[:id]).real_content
    return if @content.closed
    require_user_can_edit(@content)
    if params[:reason].to_s.strip == ''
      flash[:error] = "Debes indicar una razón para cerrar este contenido"
    else
      if @content.close(@user, params[:reason])
        flash[:notice] = "Contenido '#{@content}' cerrado a comentarios."
      else
        flash[:error] = "Error al cerrar contenido:"+
                        " #{@content.errors.full_messages_html}."
      end
    end

    redirect_to gmurl(@content)
  end

  def tag_content
    raise AccessDenied unless Authorization.can_tag_contents?(@user)
    @content = Content.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @content
    valid_terms = []
    params[:tags].split(",").each do |tag_id|
      term = Term.find_by_id(tag_id.to_i)
      next if term.nil?
      valid_terms.append(term.name)
    end

    UsersContentsTag.tag_content(
        @content,
        @user,
        valid_terms.join(" "),
        delete_missing=false)

    # TODO(slnc): crear los tags por ajax en lugar de redirigir
    redirect_to gmurl(@content)
  end

  def remove_user_tag
    raise AccessDenied unless Authorization.can_admin_tags?(@user)
    @uct = UsersContentsTag.find(
        :first,
        :conditions => ['user_id = ? AND id = ?', @user.id, params[:id]])
    raise ActiveRecord::RecordNotFound unless @uct
    @content = @uct.content
    @uct.destroy
    @js_response = "$('#one-of-my-tags#{@uct.id}').fadeOut('normal');"
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end
end
