class AccessDenied < StandardError; end
class DomainNotFound < StandardError; end

class ApplicationController < ActionController::Base  
  include Clans::Authentication
  include Users::Authentication
  
  helper :account, :miembros, :competiciones, :calendar
  before_filter :ident, :resolve_portal_mode, :check_referer, :populate_navpath2, :parse_params_page
  # before_filter :init_xab # TODO necesario por rails 2.2
  
  attr_accessor :competition, :portal, :third_menu, :global_vars
  cattr_accessor :navpath2
  
  def no_ads
    false
  end
  
  
  def can_add_as_quicklink?
    if user_is_authed && %w(FactionsPortal BazarDistrictPortal).include?(portal.class.name)
      qlinks = Personalization.quicklinks_for_user(@user)
      if qlinks.delete_if { |ql| ql[:code] != self.portal.code }.size == 0 # no estaba
        true
      else
        false
      end
    else
      false
    end
  end
  
  def can_del_quicklink?
    if user_is_authed && %w(FactionsPortal BazarDistrictPortal).include?(portal.class.name)
      qlinks = Personalization.quicklinks_for_user(@user)
      if qlinks.delete_if { |ql| ql[:code] != self.portal.code }.size == 1 # estaba
        true
      else
        false
      end
    else
      false
    end
  end
  
  def can_add_as_user_forum?
    if user_is_authed && controller_name == 'foros' && @forum
      ufs = Personalization.get_user_forums(@user)
      if ufs[0].delete_if { |ql| ql != @forum.id.to_s }.size == 0 && ufs[1].delete_if { |ql| ql != @forum.id.to_s }.size == 0 # no estaba
        true
      else
        false
      end
    else
      false
    end
  end
  
  def can_del_user_forum?
    if user_is_authed && controller_name == 'foros' && @forum
      ufs = Personalization.get_user_forums(@user)
      if ufs[0].delete_if { |ql| ql != @forum.id.to_s }.size == 1 || ufs[1].delete_if { |ql| ql != @forum.id.to_s }.size == 1 # estaba
        true
      else
        false
      end
    else
      false
    end
  end
  
  def self.taxonomy_from_content_name(content_name)
    "#{ActiveSupport::Inflector::pluralize(content_name)}Categories"
  end
  
  def self.extract_content_name_from_taxonomy(taxonomy)
    ActiveSupport::Inflector::singularize(taxonomy.gsub('Category', ''))
  end
  
  def get_category_address(category, taxonomy)
    paths = []
    navpath = []
    paths << category.name
    
    href = Cms::translate_content_name(ApplicationController.extract_content_name_from_taxonomy(taxonomy))
    href2 = href.normalize
    
    navpath << [category.name, "/#{href2}/#{category.id}"]
    
    while category.parent 
      category = category.parent
      paths << category.name
      navpath << [category.name, "/#{href2}/#{category.id}"]
    end
    
    paths = paths.reverse
    navpath = [[ActiveSupport::Inflector::titleize(href), "/#{href2}"], ] + navpath.reverse
    
    return paths, navpath
  end
  
  def parse_params_page
    params[:page] = params[:page].to_i if params[:page]
  end
  
  def redirto_or(alt)
    redirect_to(params[:redirto] ? params[:redirto] : alt)
  end
  
  def current_default_portal
    user_is_authed ? @user.default_portal : cookies[:defportalpref]
  end
  
  def can_set_as_default_home
    controller_name == 'home' && current_default_portal != action_name
  end
  
  # devuelve el dominio para el término raíz dado
  def self.get_domain_of_root_term(term)
    raise "term is not root term" unless term.id == term.root_id
    theportal = Portal.find_by_code(term.slug)
    if theportal
      "#{theportal.code}.#{App.domain}"
    elsif term.slug == 'gm'
      App.domain
    elsif %w(bazar otros).include?(term.slug)
      App.domain_bazar
    elsif %w(arena).include?(term.slug)
      App.domain_arena
    else
      App.domain
    end
  end
  
  def active_sawmode
    @active_sawmode ? @active_sawmode : wmenu_pos
  end
  
  def self.audit(*args)
    after_filter :sys_audit, :only => args
  end
  
  def self.require_admin_permission(mode)
    before_filter { |c| c.send(:require_admin_permission, mode) }
  end
  
  def wmenu_pos
    ''
  end
  
  def sys_audit
    params_copy = request.parameters.clone
    %w(password password_confirmation k vk).each do |sensible_key|
      params_copy[sensible_key] =  "******" if params_copy.has_key?(sensible_key)
    end
    
    id_prefix = ''
    %w(login email).each do |id_keyword|
      if params_copy.has_key?(id_keyword)
        id_prefix = " [#{id_keyword}=#{params_copy[id_keyword]}]"
        break
      end
    end
    
    headline = "[#{controller_path}] [#{action_name}]"
    headline<< " [id=#{params[:id]}]" if params[:id]
    headline<< id_prefix
    headline<< " [sess_user_id=#{@user.id}]" if user_is_authed
    
    info = """-------------------------------
Request information:
-------------------------------
* URL: #{request.protocol}#{request.host}#{request.request_uri}
* Remote IP: #{request.remote_ip}
* Parameters: #{params_copy.inspect}</code>"""
    SlogEntry.create({:type_id => SlogEntry::TYPES[:info], :headline => headline, :info => info, :reviewer_user_id => User.find_by_login('MrAchmed').id, :completed_on => Time.now})
  end
  
  
  def populate_navpath2
    self.class.navpath2 = []
    self.class.navpath2<< [controller_name.titleize, "/#{self.class.controller_path}"] unless action_name == 'index'
  end
  
  def navpath2
    self.class.navpath2
  end
  
  def title
    @title ||= begin
      if (@title.to_s != '') 
        @title 
      else 
        if action_name == 'index'
          controller_name.humanize
        else
          action_name.humanize
        end
      end
    end
  end
  
  # TODO PERF GmSys.job
  def check_referer
    if params[:rusid] && request.remote_ip != 'unknown'
      Stats.register_referer(params[:rusid].to_i, request.remote_ip, request.env['HTTP_REFERER'])
    end
  end
  
  def submenu
    nil
  end
  
  def url_for_content(object, text)
    self.class.url_for_content(object, text)
  end
  
  def url_for_content_onlyurl(object)
    self.class.url_for_content_onlyurl(object)
  end
  
  def gmurl(object, opts={})
    self.class.gmurl(object, opts)
  end
  
  def self.gmurl(object, opts={})
    cls_name = object.class.name
    if cls_name.index('Category')
      # DEPRECATED taxonomies
      href = Cms::translate_content_name(ActiveSupport::Inflector::singularize(cls_name.gsub('Category', '')))
      href = href.normalize
      case href
        when 'topics':
        href = "foros/forum"
        when 'preguntas':
        href = "respuestas/categoria"
        when 'anuncios-de-reclutamiento':
        href = 'reclutamiento'
      end
      dom = get_domain_of_root_term(object.root)
      "http://#{dom}/#{href}/#{object.id}"
    elsif cls_name == 'Term'
      if object.taxonomy.nil? && opts[:taxonomy].nil?
        raise "gmurl for term without taxonomy specified"
      else
        opts[:taxonomy] = object.taxonomy unless opts[:taxonomy]
        if opts[:taxonomy].index('Category')
          href = Cms::translate_content_name(ActiveSupport::Inflector::singularize(opts[:taxonomy].gsub('Category', '')))
          href = href.normalize
          case href
            when 'topics':
            href = "foros/forum"
            when 'preguntas':
            href = "respuestas/categoria"
            when 'anuncios-de-reclutamiento':
            href = 'reclutamiento'
          end
          dom = get_domain_of_root_term(object.root)
          "http://#{dom}/#{href}/#{object.id}"
        else
          raise "gmurl for term with unrecognized taxonomy '#{opts[:taxonomy]}'"
        end
      end
    elsif cls_name == 'Faction'
      "http://#{object.code}.#{App.domain}/"
    elsif cls_name == 'Clan'      
      "http://#{App.domain}/clanes/clan/#{object.id}"
    elsif %w(Competition League Ladder Tournament).include?(cls_name)      
      "http://arena.#{App.domain}/competiciones/show/#{object.id}"
    elsif %w(Friend User).include?(cls_name)
      # TODO the right way would be URI.escape('b@rto',Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) but we only have problems with @ right now so I hack it
      "http://#{App.domain}/miembros/#{object.login.gsub('@', '%40')}"
    elsif nil
      raise "Nil object can't have url"
    else
      ApplicationController.url_for_content_onlyurl(object)
    end
  end
  
  def ApplicationController.url_for_content_onlyurl(object)
    uniq = object.class.name == 'Content' ?  object : object.unique_content
    if uniq.url.nil?
      # actualizamos url y portal_id
      # competitions
      # %w(Competition CompetitionsMatch)
      
      object = uniq.real_content
      cls_name = object.class.name
      # determinamos dominio
      if %w(Funthing).include?(cls_name)
        dom = App.domain_bazar
        portal_id = BazarPortal.new.id
        #elsif %w(Demo Bet).include?(cls_name)
        #  dom = App.domain_arena
        #  portal_id = ArenaPortal.new.id
      elsif cls_name == 'Blogentry'
        dom = App.domain
        portal_id = GmPortal.new.id
      elsif cls_name == 'Coverage'
        dom = get_domain_of_root_term(object.event.main_category.root)
      elsif Cms::CONTENTS_WITH_CATEGORIES.include?(cls_name)
        
        maincat = object.main_category
        if maincat
          dom = get_domain_of_root_term(maincat.root)
        else
          dom = App.domain  
        end
      else
        raise "url_for_content_onlyurl() #{cls_name} not understood}"
      end
      
      d = dom.gsub(".#{App.domain}", '')
      d = 'gm' if d == "" || d == App.domain
      
      if %w(gm arena bazar).include?(d)
        portal_id = Object.const_get("#{d.titleize}Portal").new.id
      else
        portal_id = Portal.find_by_code(d).id
      end
      
      href = Cms::translate_content_name(object.class.name)
      href = href.normalize
      # TODO quitar esto y usar gmurl
      if href == 'topics' then
        out = "/foros/topic/#{object.id}"
      elsif href == 'preguntas' then
        out = "/respuestas/show/#{object.id}"
      elsif href == 'anuncios-de-reclutamiento' then
        out = "/reclutamiento/anuncio/#{object.id}"
      elsif object.class.name == 'Blogentry' then
        out = "/blogs/#{object.user.login}/#{object.id}"
      elsif object.class.name == 'Event'
        cm = CompetitionsMatch.find_by_event_id(object.id)
        if cm
          out = "/competiciones/partida/#{cm.id}"
        else
          out = "/#{href}/show/#{object.id}"
        end
      elsif object.class.name == 'Coverage' then
        out = "/coverages/show/#{object.id}"
      else
        out = "/#{href}/show/#{object.id}"
      end
      uniq.url = "http://#{dom}#{out}"
      uniq.portal_id = portal_id
      User.db_query("UPDATE contents SET url = #{User.connection.quote(uniq.url)}, portal_id = #{portal_id} WHERE id = #{uniq.id}")
      User.db_query("UPDATE comments SET portal_id = #{portal_id} WHERE content_id = #{uniq.id}")
    end
    uniq.url
  end
  
  def ApplicationController.url_for_content(object, text)
    "<a class=\"content\" href=\"#{ApplicationController.url_for_content_onlyurl(object)}\">#{text}</a>"
  end
  
  
  
  
  
  
  
  
  
  def admin_menu_items
    return [] unless user_is_authed 
    # TODO hack
    items = []
    if user.is_superadmin?
      items<< ['Ads', '/admin/ads']
      items<< ['Ads Slots', '/admin/ads_slots']
      items<< ['Canales GMTV', '/admin/canales']
      items<< ['Competiciones', '/admin/competiciones']
      items<< ['Grupos', '/admin/grupos']
      items<< ['Hipótesis', '/admin/hipotesis']
      items<< ['Juegos', '/admin/juegos']
      items<< ['Notificaciones globales', '/admin/global_notifications']
      items<< ['Plataformas', '/admin/plataformas'] 
      items<< ['Portales', '/admin/portales']
      items<< ['Scripts', '/admin/scripts']
      items<< ['Tienda', '/admin/tienda']
    end
    
    if user.is_superadmin? || user.has_admin_permission?(:capo)
      items<< ['Avatares', '/avatares']
      items<< ['Clanes', '/admin/clanes']
      items<< ['IP Bans', '/admin/ip_bans']
      items<< ['Mapas', '/admin/mapas_juegos']
      items<< ['Users', '/admin/usuarios']
      items<< ['Facciones', '/admin/facciones']
    end
    
    if user.is_superadmin? || user.has_admin_permission?(:bazar_manager) || user.has_admin_permission?(:capo) 
      items<< ['Cat Contenidos', '/admin/categorias']
    end
    
    if user.is_superadmin? || user.has_admin_permission?(:faq)
      items<< ['Entradas FAQ', '/admin/entradasfaq']
      items<< ['Cat FAQ', '/admin/categoriasfaq']
    end
    
    if user.is_superadmin? || user.has_admin_permission?(:bazar_manager)
      items<< ['Distritos bazar', '/admin/bazar_districts']
    end
    
    
    items<< ['Motor (info)', '/admin/motor']
    
    # ordenamos las entradas
    items2 = {}
    items.each { |i| items2[i[0]] = i[1] }
    items3 = []
    items2.keys.sort.each { |k| items3<< [k, items2[k]]}
    
    items3
  end
  
  def clanes_menu_items
    l = []
    
    if @user.last_clan_id then
      l<<['Portada', '/cuenta/clanes']
      
      if @clan.user_is_clanleader(@user.id) then
        l<<['Configuración', '/cuenta/clanes/configuracion']
        l<<['Miembros', '/cuenta/clanes/miembros']
        l<<['Clanes amigos', '/cuenta/clanes/amigos']
        l<<['Sponsors', '/cuenta/clanes/sponsors']
        l<<['Banco', '/cuenta/clanes/banco']
        if @portal.kind_of?(ClansPortal)
          l<<['Categorías de contenidos', "/admin/categorias"]
          l<<['Skin', "/cuenta/skins/edit/#{@portal.skin_id}"]
        end
      end
    end
    
    l
  end
  
  around_filter :gm_process
  # Used to be able to leave out the action
  def gm_process
    @_track_done = false
    seconds = Benchmark.realtime do
      catch(:abort) do
        yield
      end
    end
    
    begin
      Stats.pageloadtime(self, seconds, response, controller_name, action_name, portal)
    rescue 
      raise unless RAILS_ENV == 'test'
    end
  end

  
  def resolve_portal_mode
    @global_vars = User.db_query("SELECT * FROM global_vars")[0]
    # esto no hay que hacerlo aquí
    # hay clientes que mandan un HTTP_CLIENT_IP incorrecto TODO esto peta
    if request.env.include?('HTTP_CLIENT_IP') and (request.env['HTTP_CLIENT_IP'] =~ /^unknown$|^(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\./i).nil? then
      request.env['HTTP_CLIENT_IP'] = request.env['REMOTE_ADDR']
    end

    if [App.domain, 'kotoko'].include?(request.host) 
      @portal = GmPortal.new
    elsif request.host == "bazar.#{App.domain}"
      @portal = BazarPortal.new
    elsif request.host == "arena.#{App.domain}"
      @portal = ArenaPortal.new
    else
      # buscamos un portal para el host dado
      host = request.host.gsub(/\.$/, '') # hay gente q pone los dominios con punto al final
      km = host.match(/([^.]+\.[^.]+)$/)
      raise DomainNotFound if km.nil? # blank host or invalid name
      k = km[1]
      @@portals ||= {}
      @@portals = {} if RAILS_ENV == 'test' 
      if not @@portals.has_key?(host) then
        if App.domain_aliases.include?(k)
          raise DomainNotFound # ya no soportamos los dominios viejos
        else
          ptal = Portal.find_by_code(host.match('^([^.]+)[.]+')[1])
          ptal = Portal.find_by_fqdn(k) if ptal.nil?
          @@portals[host] = ptal
        end
      end
      
      @portal = @@portals[host]
      raise DomainNotFound if @portal.nil?
      @portal_clan = @portal.clan if @portal.clan_id
    end
  end
  
  layout 'portal_gm'
  
  public
  def skin
    if session[:skin]
      Skin.find_by_hid(session[:skin]) || Skin.find_by_hid('default')
    elsif portal.skin_id != nil
      Skin.find(portal.skin_id) || Skin.find_by_hid('default')
    else
      portal.skin # Skin.find_by_hid(portal)
    end
  end
  
  def check_portal_access_mode(allowed_portals)
    if defined?(allowed_portals) and not allowed_portals.include?(ActiveSupport::Inflector::singularize(ActiveSupport::Inflector::underscore(@portal.class.name.gsub('Portal', ''))).to_sym)
      raise ActiveRecord::RecordNotFound 
    end
  end
  
  def self.allowed_portals(class_names)
    before_filter { |c| c.check_portal_access_mode(class_names) }
  end
  
  def portal_code
    @portal.code if @portal
  end
  
  def is_crawler?
    @_is_crawler ||= request.user_agent.to_s != '' && (/bot|mediapartners|slurp/ =~ request.user_agent.downcase)
    @_is_crawler
  end
  
  def check404
    if 1 == 0 && request.env.include?('HTTP_REFERER') && request.env['HTTP_REFERER'].to_s != '' && request.env['HTTP_REFERER'].index('gamersmafia')
      uri = "http://#{request.env['HTTP_X_FORWARDED_HOST']}#{request.request_uri}"
      SystemNotifier.deliver_notification404_notification(request.request_uri, request.env['HTTP_REFERER'], request)
    end
  end
  
  VERSIONING_EREG = /^\/(.*\.)[a-z0-9.]+\.(css|js|gif|png|jpg)$/
  
  def http_404
    if App.port != 80 # solo capturamos estas URLs cuando ejecutamos en desarrollo
      res = request.request_uri.match(VERSIONING_EREG)
      if res
        if %w(gif png jpg).include?(res[2])
          base = 'image'
        else
          base = 'text'
        end
        if res[2] == 'js'
          ext = 'javascript'
        else
          ext = res[2]
        end
        response.headers["Content-Type"] = "#{base}/#{ext}"
        if %w(css js).include?(res[2])
          render :file => "#{RAILS_ROOT}/public/#{res[1]}#{res[2]}"
        else
          send_file "#{RAILS_ROOT}/public/#{res[1]}#{res[2]}"
        end
      else
        @title = "Página no encontrada (Error 404)"
        render :template => 'application/http_404', :status => 404
      end
    else
      @title = "Página no encontrada (Error 404)"
      render :template => 'application/http_404', :status => 404
    end
  end
  
  def http_401
    @title = "Acceso Denegado (Error 401)"
    render :template => 'application/http_401', :status => 401
  end
  
  #def rescue_action_locally(exception)
  #  rescue_action_in_public(exception)
  #end
  
  include ExceptionNotifiable
  ExceptionNotifier.exception_recipients = %w(rails-gm@slnc.net)
  ExceptionNotifier.sender_address = %("GM Error Notifier" <httpd@gamersmafia.com>)

  def rescue_action_in_public(exception)
    case exception
      when ActiveRecord::RecordNotFound
      check404
      http_404
      
      when DomainNotFound
      redirect_to("http://#{App.domain}", :status => 301)
      
      when ContentLocked
      render(:layout => 'portal_gm', :file => "#{RAILS_ROOT}/app/views/site/content_locked.rhtml", :status => '403 Forbidden')
      
      when AccessDenied
      http_401
      
      when ::ActionController::UnknownAction, ::ActionController::RoutingError
      if request.path.index('www.') != nil then
        redirect_to("http://#{request.path[request.path.index('www.')..-1]}", :status => 301)
      else
        check404
        http_404
      end
    else
deliverer = self.class.exception_data
          data = case deliverer
            when nil then {}
            when Symbol then send(deliverer)
            when Proc then deliverer.call(self)
          end
 
          ExceptionNotifier.deliver_exception_notification(exception, self,
            request, data)

      # SystemNotifier.deliver_exception_notification(self, request, exception)
      begin
        render :template => 'application/http_500', :status => 500
      rescue
        #layout nil
        # render :file => "#{RAILS_ROOT}/app/views/application/http_500.rhtml", :status => 500
        render(:file => "#{RAILS_ROOT}/public/500.html", :status => '500 Error')
      end
    end
  end
  
  public
  def track(opts={})
    opts = {:redirecting => false, :cookiereq => true }.merge(opts)
    user_id = user_is_authed ? @user.id : 'NULL'
    user_agent = request.user_agent.to_s != '' ? request.user_agent : ''
    cka = cookies['__stma']
    
    return if @_track_done # no entiendo por qué está pasando pero se llama dos veces desde redirect_to
    return if !cka && opts[:cookiereq] # no trackeamos lo que no podemos cookear
    
    if opts[:redirecting]
      params['_xvi'] = cka.split('.')[1]
      params['_xsi'] = cka.split('.')[3]
      params['_xmi'] = params[:id]
      params['_xc'] = controller_name
      params['_xa'] = action_name
      url = request.request_uri
    else
      url = params['_xu']  
    end
    @_track_done = true
    
    # si el user_id tiene un visitor_id ya asignado en users usamos ese
    if user_is_authed
      if @user.visitor_id.to_s != ''
        cookies['__stma'] = { :value => cookies['__stma'].gsub(params['_xvi'], @user.visitor_id), :domain => COOKIEDOMAIN, :expires => 2.years.since}
        params['_xvi'] = @user.visitor_id
      else
        if User.find_by_visitor_id(params['_xvi']) # otro usuario se ha conectado desde ese pc
          new_visitor_id = (Kernel.rand * 2147483647).to_i.to_s # TODO no debería repetirse 
          @user.visitor_id = new_visitor_id
          cookies['__stma'] = { :value => cookies['__stma'].gsub(params['_xvi'], @user.visitor_id), :domain => COOKIEDOMAIN, :expires => 2.years.since}
          params['_xvi'] = @user.visitor_id
        else # primer visitor_id del usuario
          @user.visitor_id = params['_xvi']
          User.db_query("UPDATE users SET visitor_id = #{User.connection.quote(params['_xvi'].to_s)} WHERE id = #{@user.id}")
        end
      end
    end
    
    if params['_xab'].to_s != '' then # check que lo hayamos añadido a treated_visitors     
      # TODO debemos modificar el _xab enviado de forma que no lo puedan adulterar para manipular los tests
      # TODO esto debe ir en AbTest
      params['_xab'].each do |test_id, treatment_id|
        test_id = test_id.to_i
        treatment_id = treatment_id.to_i
        
        #if user_is_authed
        # tu = TreatedUser.find(:first, :conditions => [:ab_test_id => test_id.to_i, visitor_id => params['_xvi'].to_s])
        #end
        if user_is_authed
          dbu = User.db_query("SELECT * 
                               FROM treated_visitors 
                              WHERE ab_test_id = #{test_id.to_i} 
                                AND (visitor_id = #{User.connection.quote(params['_xvi'].to_s)}
                                 OR user_id = #{@user.id})
                            ORDER BY id")
        else
          dbu = User.db_query("SELECT * 
                               FROM treated_visitors 
                              WHERE ab_test_id = #{test_id.to_i} 
                                AND visitor_id = #{User.connection.quote(params['_xvi'].to_s)}")
        end
        
        if dbu.size == 0 then # create entry
          if user_is_authed
            User.db_query("INSERT INTO treated_visitors(ab_test_id, visitor_id, treatment, user_id) VALUES(#{test_id}, #{User.connection.quote(params['_xvi'].to_s)}, #{treatment_id}, #{@user.id});")
          else
            User.db_query("INSERT INTO treated_visitors(ab_test_id, visitor_id, treatment) VALUES(#{test_id}, #{User.connection.quote(params['_xvi'].to_s)}, #{treatment_id});")
          end
        else
          
          if dbu.size == 1 and user_is_authed && treatment_id.to_i != dbu[0]['treatment'].to_i
            if dbu[0]['user_id'].to_i != @user.id # dos users usan el mismo pc
              new_visitor_id = (Kernel.rand * 2147483647).to_i.to_s
              cookies['__stma'] = { :value => cookies['__stma'].gsub(params['_xvi'], new_visitor_id), :domain => COOKIEDOMAIN, :expires => 2.years.since}
              params['_xvi'] = new_visitor_id # order is important
              User.db_query("INSERT INTO treated_visitors(ab_test_id, visitor_id, treatment, user_id) VALUES(#{test_id}, #{User.connection.quote(params['_xvi'].to_s)}, #{treatment_id}, #{@user.id});")
            elsif dbu.size == 1 && dbu[0]['visitor_id'] != params['_xvi'] # mismo user desde 2 pcs distintos
              cookies['__stma'] = { :value => cookies['__stma'].gsub(params['_xvi'], dbu[0]['visitor_id']), :domain => COOKIEDOMAIN, :expires => 2.years.since}
              params['_xvi'] = dbu[0]['visitor_id'] 
              User.db_query("UPDATE treated_visitors SET treatment = #{treatment_id.to_i}, user_id = #{@user.id} WHERE id = #{dbu[0]['id']};")
            else 
              User.db_query("UPDATE treated_visitors SET treatment = #{treatment_id.to_i}, user_id = #{@user.id} WHERE id = #{dbu[0]['id']};")              
            end
            
            # TODO analizar hits pasados y actualizarlos correspondiente aunque no es tan grave ya que como ahora ya no figura en tabla treated_visitors esos hits/conversiones se ignorarán hasta el punto en que el usuario se autentificó
            # En caso de que dos usuarios usen el mismo pc ahora mismo se asigna un nuevo visitor_id 
            # al nuevo usuario de forma que no se machaque. Cuando el nuevo user haga login en otro pc
            # el sistema cogerá el tratamiento adecuado 
            # si un user_id, test ya se encuentra en treated_visitors para un visitor_id que ahora se identifica como otro user hay que crear un nuevo visitor_id
          end
        end
      end
      params['_xab'] = params['_xab'].to_json
    end
    
    referer = params['_xr'] ? params['_xr'] :  (request.env['HTTP_REFERER'] ? request.env['HTTP_REFERER'] : '-')
    
    medium = params['_xm'] ? params['_xm'] : 'default'
    campaign = params['_xca'] ? params['_xca'] : '-'
    ip = request.remote_ip
    # TODO PERF guardar informacion del visitante en tabla aparte
    user_agent = user_agent.normalize unless user_agent.to_s.index('Aulas de Inform').nil?
    # flash_error = #{User.connection.quote(params['_xe'])}
    User.db_query("INSERT INTO stats.pageviews(referer, 
                                               user_id, 
                                               ip,  
                                               url,
                                               campaign,
                                               flash_error,
                                               abtest_treatment,
                                               ads_shown,
                                               source,
                                               medium,
                                               user_agent,
                                               portal_id,
                                               visitor_id,
                                               session_id,
                                               model_id, 
                                               controller,
                                               action) 
                                   VALUES (#{User.connection.quote(referer)}, 
                                            #{user_id}, 
                                            '#{ip}', 
                                            #{User.connection.quote(url)},
                                            #{User.connection.quote(campaign)},
                                            '',
                                            #{User.connection.quote(params['_xab'])},
                                            #{User.connection.quote(params['_xad'])},
                                            #{User.connection.quote(params['_xs'])},
                                            #{User.connection.quote(medium)},
                                            #{User.connection.quote(user_agent)},
                                            #{portal.id},
                                            #{User.connection.quote(params['_xvi'])},
                                            #{User.connection.quote(params['_xsi'])},
                                            #{User.connection.quote(params['_xmi'])},
                                            #{User.connection.quote(params['_xc'])},
                                            #{User.connection.quote(params['_xa'])}
                  )")
  end
  
  def redirect_to(*args)
    track(:redirecting => true)
    super
    #old_redirect_to(*args)
  end
  # end tracking
  
  
  protected
  def track_item(obj)
    if user_is_authed
      tracker_item = TrackerItem.find(:first, :conditions => ["user_id = ? and content_id = ? and lastseen_on is not null", @user.id, obj.unique_content.id])
      if (tracker_item && tracker_item.lastseen_on)
        @object_lastseen_on =  tracker_item.lastseen_on
        @first_time_content = false
      else
        @first_time_content = true
        Time.at(1)
      end
    end
    
    user_is_authed ? obj.hit_reg(@user) : obj.hit_anon
  end
  
  public 
  def save_or_error(model, success_dst, error_render_action)
    @name_action_participe = model.id.nil? ? 'creado' : 'actualizado'
    @name_action_infinitive = model.id.nil? ? 'crear' : 'actualizar'
    if model.save
      flash[:notice] = "#{model.class.name} #{@name_action_participe} correctamente."
      redirect_to (success_dst.kind_of?(String) ? success_dst.gsub("@#{ActiveSupport::Inflector::underscore(model.class.name)}.id", model.id.to_s) : success_dst)
    else
      flash[:error] = "Error al #{@name_action_infinitive} el #{model.class.name}: #{model.errors.full_messages_html}"
      render :action => error_render_action
    end
  end
  
  def update_attributes_or_error(model, success_dst, error_render_action)
    if model.update_attributes(params[ActiveSupport::Inflector::underscore(model.class.name)])
      flash[:notice] = "#{model.class.name} actualizado correctamente."
      redirect_to success_dst.kind_of?(String) ? success_dst.gsub("@#{ActiveSupport::Inflector::underscore(model.class.name)}.id", model.id.to_s) : success_dst
    else
      flash[:error] = "Error al actualizar el #{model.class.name}: #{model.errors.full_messages_html}"
      render :action => error_render_action
    end
  end
  
  def confirmar_nueva_cuenta(u)
    u.confirm_tasks
    session[:user] = u.id
  end
end
