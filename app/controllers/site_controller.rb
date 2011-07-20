require 'md5'

class SiteController < ApplicationController
  helper :miembros
  CONTACT_MAGIC = 982579815691299191

  def banners
    @title = 'Banners de Gamersmafia'
  end

  def responsabilidades
  end

  def gmcity
    @title = 'Gamersmafia City (por 2_Face)'
  end

  def novedades
    @title = 'Novedades sobre la web'
  end

  def el_callejon
    raise AccessDenied unless user_is_authed
    @title = 'El callejón'
  end

  def portales

  end

  def banners_bottom
    render :layout => false
  end

  def get_banners_of_gallery
    raise ActiveRecord::RecordNotFound unless params[:gallery] && params[:gallery] =~ /[a-zA-Z0-9_-]+/
    @banners = (Dir.entries("#{RAILS_ROOT}/public/images/banners/#{params[:gallery]}") - %w(. ..)).sort
    render :layout => false
  end

  def banners_duke
    files = []
    for f in Dir.entries("#{RAILS_ROOT}/public/images/banners/duke_nukem")
      if not f.index('_88x31.gif').nil? then
        files<< f
      end # if
    end # for

    filename = files[Kernel.rand(files.length)]
    send_file "#{RAILS_ROOT}/public/images/banners/duke_nukem/#{filename}",
              :type => 'image/gif',
              :disposition => 'inline'
  end

  def banners_misc
    files = []
    for f in Dir.entries("#{RAILS_ROOT}/public/images/banners")
      if not f.index('misc_120x60_').nil? then
        files<< f
      end # if
    end # for

    filename = files[Kernel.rand(files.length)]
    send_file "#{RAILS_ROOT}/public/images/banners/#{filename}",
              :type => 'image/gif',
              :disposition => 'inline'
  end

  def faq
    # TODO cache
    @title = 'Ayuda - FAQ'
  end

  def raise404_if(condition)
    raise ActiveRecord::RecordNotFound if condition
  end

  def rate_content
    self.raise404_if(params[:content_rating].nil? ||
                     params[:content_rating][:rating].nil?)

    params[:content_rating][:ip] = request.remote_ip
    params[:content_rating][:user_id] = @user.id if user_is_authed
    rating = ContentRating.new(params[:content_rating])

    if user_is_authed && @user.can_rate?(rating.content.real_content) then
      rating.save
    elsif !user_is_authed && ContentRating.count(:conditions => ['user_id is null and content_id = ? and ip = ?', rating.content_id, rating.ip]) == 0
      rating.save
    end

    @obj = rating.content.real_content
    render :layout => false
  end

  def clean_html
    require_auth_users
    if params[:raw_post_data]
      rpd = params[:raw_post_data]
      params[:editorId] = rpd.match('editorId=([a-zA-Z0-9\[\]]+)&')[1]
      params[:content] = rpd.match('editorId=[a-zA-Z0-9\[\]]+&content=(.*)$')[1]
    end
    @content = Cms::clean_html(CGI::unescape(params[:content]))
    response.headers["Content-Type"] = 'text/xml'
    render :layout => false
  end

  def staff
  end

  def index
    @title = 'Acerca de la web'
  end

  def acercade
    redirect_to '/site' # TODO eliminar en el futuro
  end

  def netiquette
    @title = 'Código de Conducta'
  end

  def chat
    @title = "Chat Gamersmafia"
    @online_users = User.can_login.online.find(:all, 
                                               :order => 'lastseen_on desc',
                                               :limit => 100)
  end

  def update_chatlines
    if cookies.keys.include?('chatpref') and cookies['chatpref'].to_s == 'big' then
      render :layout => false, :action => 'update_chatlines_big'
    else
      render :layout => false, :action => 'update_chatlines_mini'
    end
  end

  def new_chatline
    require_auth_users
    # TODO copypasted
    chatline = Chatline.new
    chatline.line = params[:line][0..450].strip
    chatline.line = chatline.line.gsub(/</, '&lt;')
    chatline.line = chatline.line.gsub(/>/, '&gt;')
    chatline.user_id = @user.id

    if chatline.line != '' then
      chatline.save
    end

    @title = 'Usuarios Online'
    @user.lastseen_on = Time.now
    @user.save

    @clear_comment_line = true

    if cookies.keys.include?('chatpref') and cookies['chatpref'].to_s == 'big' then
      @online_users = User.find(:all, :conditions => 'lastseen_on >= now() - \'30 minutes\'::interval', :order => 'lastseen_on desc', :limit => 100)
      render :layout => false, :action => 'update_chatlines_big'
    else
      @online_users = User.find(:all, :conditions => 'lastseen_on >= now() - \'30 minutes\'::interval', :order => 'faction_id asc, lastseen_on desc', :limit => 100)
      render :layout => false, :action => 'update_chatlines_mini'
    end
  end

  def del_chatline
    chatline = Chatline.find(params[:id])
    require_user_can_edit(chatline)
    chatline.destroy
    @title = 'Usuarios Online'
    @clear_comment_line = true

    if cookies.keys.include?('chatpref') and cookies['chatpref'].to_s == 'big' then
      @online_users = User.find(:all, :conditions => 'lastseen_on >= now() - \'30 minutes\'::interval', :order => 'lastseen_on desc', :limit => 100)
      render :layout => false, :action => 'update_chatlines_big'
    else
      @online_users = User.find(:all, :conditions => 'lastseen_on >= now() - \'30 minutes\'::interval', :order => 'faction_id asc, lastseen_on desc', :limit => 100)
      render :layout => false, :action => 'update_chatlines_mini'
    end
  end

  def add_to_tracker
    require_auth_users
    Users.add_to_tracker(@user, Content.find(params[:id]))
    redirect_to params[:redirto]
  end

  def del_from_tracker
    require_auth_users
    Users.remove_from_tracker(@user, Content.find(params[:id]))
    redirect_to params[:redirto]
  end

  def get_non_updated_tracker_items
    response.headers["Cache-Control"] = "no-cache"
    render :layout => false
    response.headers["Cache-Control"] = "no-cache"
  end

  def trastornos
    @title = 'Trastornos psíquicos'
  end

  def ejemplos_guids
    @title = 'Ejemplos de GUIDs'
    render :layout => 'popup'
  end

  def confirmar_transferencia
    require_auth_users

    params[:redirto] = '/' unless params[:redirto]

    @title = 'Confirmar transferencia'
    if params[:recipient_class] == 'User'
      @recipient = User.find(:first, :conditions => ['login = ? AND created_on <= now() - \'1 month\'::interval', params[:recipient_user_login]]) #_by_login(params[:recipient_user_login])
    elsif params[:recipient_class] == 'Clan'
      @recipient = Clan.find_by_name(params[:recipient_clan_name])
    else
      cls = Object.const_get(params[:recipient_class]) if params[:recipient_class] && params[:recipient_class] != ''
       (@recipient = cls.find(params["recipient_#{params[:recipient_class]}_id".to_sym])) if cls
    end

    if not defined?(@recipient) or @recipient.nil?
      flash[:error] = 'No se ha encontrado el destinatario especificado.'
      redirect_to params[:redirto] and return
    elsif params[:description].to_s.strip == ''
      flash[:error] = 'La descripción no puede estar en blanco.'
      redirect_to params[:redirto] and return
    else
      @sender = Object.const_get(params[:sender_class]).find(params[:sender_id])

      if params[:ammount].to_f <= 0 || @sender.cash < 0 || @sender.cash < params[:ammount].to_f then
        flash[:error] = 'No tienes el dinero suficiente para hacer esa transferencia'
        redirect_to params[:redirto] and return
      else
        case @sender.class.name
          when 'Clan'
          raise AccessDenied unless @sender.user_is_clanleader(@user.id)
          when 'Competition'
          raise AccessDenied  unless @sender.user_is_admin(@user.id)
          when 'User'
          raise AccessDenied unless @user.id == @sender.id
          when 'Faction'
          raise AccessDenied unless @sender.is_boss?(@user)
          when 'User'
          raise AccessDenied unless @user.id == @sender.id
        end
      end

      if @sender.class.name == @recipient.class.name && @sender.id == @recipient.id
        flash[:error] = 'El destinatario debe ser distinto del remitente.'
        redirect_to params[:redirto]
      end
    end
  end

  def transferencia_confirmada
    require_auth_users
    sender = Object.const_get(params[:sender_class]).find(params[:sender_id])

    case sender.class.name
      when 'Clan'
      raise AccessDenied unless sender.user_is_clanleader(@user.id)
      when 'Competition'
      raise AccessDenied unless sender.user_is_admin(@user.id)
      when 'Faction'
      raise AccessDenied unless sender.is_boss?(@user)
    end

    if params[:ammount].to_f < 0 || sender.cash < 0 || sender.cash < params[:ammount].to_f then
      flash[:error] = 'No tienes el dinero suficiente para hacer esa transferencia'
      redirect_to params[:redirto]
    else
      recipient = Object.const_get(params[:recipient_class]).find(params[:recipient_id])
      if recipient.class.name == 'User' and recipient.created_on >= 2.months.ago
        raise ActiveRecord::RecordNotFound
      end
      Bank.transfer(sender, recipient, params[:ammount].to_f, params[:description])
      flash[:notice] = 'Transferencia realizada correctamente.'
      redirect_to params[:redirto]
    end
  end

  def http_401
    raise AccessDenied
  end

  def http_500
    raise Exception
  end

  def unserviceable_domain
    @title = 'Dominio fuera de servicio'
  end

  def maintain_lock
    require_auth_users
    lock = ContentsLock.find(:first, :conditions => ['id = ? and user_id = ?', params[:id], @user.id])
    raise ActiveRecord::RecordNotFound unless lock
    lock.save
    render :nothing => true
  end

  def macropoll_send
    user_id = user_is_authed ? @user.id : 'NULL'
    if user_is_authed and User.db_query("SELECT * FROM macropolls WHERE poll_id = 1 AND user_id = #{user_id}").size == 0 then
      Bank::transfer(:bank, @user, 10, "Agradecimiento por completar la encuesta global")
      flash[:notice] = "Te hemos ingresado 10GMF como muestra de nuestro agradecimiento. No, no la puedes rellenar más veces."
      User.db_query("INSERT INTO macropolls(poll_id, host, ipaddr, user_id, answers) VALUES(1, '#{request.host}', '#{request.remote_ip}', #{user_id}, '#{YAML::dump(params)}')")
    elsif !user_is_authed
      User.db_query("INSERT INTO macropolls(poll_id, host, ipaddr, user_id, answers) VALUES(1, '#{request.host}', '#{request.remote_ip}', #{user_id}, '#{YAML::dump(params)}')")
    end
    redirect_to :action => :macropoll_thanks
  end

  def macropoll_thanks
  end

  def te_buscamos
    # TODO controls
    @title = 'Te buscamos'
  end

  def cnta
    raise ActiveRecord::RecordNotFound unless params[:url]
    user_id = user_is_authed ? @user.id : 'NULL'
    element_id = (/([a-zA-Z0-9_-])/ =~ params[:element_id]) ? params[:element_id] : 'NULL'
    user_agent = (request.user_agent.to_s != '') ? request.user_agent : ''
    referer = request.env['HTTP_REFERER'] ? request.env['HTTP_REFERER'] : ''
    portal_id = @portal.id != -1 ? @portal.id : 'NULL'
    url = params[:url]
    ip = request.remote_ip
    cka = cookies['__stma']
    if cka
      params['_xvi'] = cka.split('.')[1]
      params['_xsi'] = cka.split('.')[3]
    else
      params['_xvi'] = nil
      params['_xsi'] = nil
    end


    # TODO HACK
    pdata = /ad[0-9]+--ab([0-9-]+)r([0-9]+)l([0-9]+)/.match(element_id)
    # TODO temp disabled
    if nil && pdata # /--/ =~ element_id # bandit algorithm tracking
      game_id = pdata[1]
      lever = pdata[3].to_i
      round = pdata[2].to_i

      data = User.db_query("SELECT lever#{lever}_reward FROM stats.bandit_treatments WHERE abtest_treatment = '#{game_id}'")
      if data.size == 0
        raise "game data for #{game_id} NOT FOUND"
      end
      data = data[0]["lever#{lever}_reward"]
      data[round..round] = '1'
      # new_data = gambler.rewards[lever]['t']
      User.db_query("UPDATE stats.bandit_treatments
                          SET lever#{lever}_reward = '#{data}'
                        WHERE abtest_treatment = '#{game_id}'")
      #else
      #  User.db_query("UPDATE stats.bandit_treatments
      #                    SET lever#{lever}_reward = lever#{lever}_reward | (lpad('', #{round}, '0') || '1')::bit(#{round + 1})
      #                  WHERE abtest_treatment = '#{game_id}'")
      #end
    end

    User.db_query("INSERT INTO stats.ads (referer,
                                          user_id,
                                          ip,
                                          user_agent,
                                          portal_id,
                                          visitor_id,
                                          session_id,
                                          url,
                                          element_id)
                                   VALUES (#{User.connection.quote(referer)},
                                            #{user_id},
                                            '#{ip}',
                                            #{User.connection.quote(user_agent)},
                                            #{portal_id},
                                            #{User.connection.quote(params['_xvi'])},
                                            #{User.connection.quote(params['_xsi'])},
                                            #{User.connection.quote(url)},
                                            '#{element_id}')")
    head :created, :location => request.request_uri
  end

  def stats_hipotesis
    require_auth_hq
    @title = "Hipótesis activas"
    @active_sawmode = 'hq'
  end

  def stats_hipotesis_archivo
    require_auth_hq
    @title = "Hipótesis completadas"
    @active_sawmode = 'hq'
  end

  def x
    track
    response.headers["Cache-Control"] = "no-cache"

    # antiguo update_online_state
    # TODO refactorizar y usar stats.pageviews !!!
    # TODO mover a otro sitio
    if user_is_authed then
      #reg
      if @user.lastseen_on.to_i < Time.now.to_i - 60 then
        if @user.lastseen_on.to_i < (Time.now.to_i - 86400 * 90) and (not @user.resurrected_by_user_id.nil? and @user.resurrection_started_on > Time.now - 86400 * 7) then
          # resurrección ejecutada con éxito!
          @user.resurrect
        end

        @user.update_attributes(:lastseen_on => Time.now, :ipaddr => request.remote_ip)
      end
    end
    render :layout => false
  end

  def i
    track(:cookiereq => false)
    send_file "#{RAILS_ROOT}/public/images/blank.gif", :type => 'image/gif', :disposition => 'inline'
  end

  def smileys
    # TODO make it cacheable
    render :layout => false
  end

  def search
    params[:id] = params[:searchq]
    redirect_to "http://google.com/search?num=100&filter=0&safe=off&q=site%3Agamersmafia.com #{params[:searchq]}"
  end

  def webmasters
    # @title = "Webmasters"
  end

  def rss
    @title = "RSS"
  end

  def contactar
  end

  def privacidad
    @title = "Política de privacidad"
  end

  def logoe
    if params[:mid]
      se = SentEmail.find(:first, :conditions => ['message_key = ? AND first_read_on is null', params[:mid]])
      se.update_attribute(:first_read_on, Time.now) if se
    end
    send_file "#{RAILS_ROOT}/public/skins/default/images/notifications/logo.gif", :type => 'image/gif', :disposition => 'inline'
  end

  def do_contactar
    raise ActiveRecord::RecordNotFound unless params[:subject].to_s != '' && params[:message].to_s != ''
    forbidden = %w(justinmadridsssd@gmail.com seo.sales.traffic@gmail.com traffic.internet.marketing@gmail.com seo.sales.traffic@gamil.com justinmadridsssd@gmail.com)
    if params[:subject] == ''
	    flash[:error] = 'Por favor, elige una categor�a para tu mensaje'
    else
      flash[:notice] = "Mensaje recibido correctamente. Muchas gracias por tu tiempo."
      (redirect_to '/site/contactar' and return) if params[:subject] == 'seo' || (params[:email] && forbidden.include?(params[:email]))
    # TODO más protecciones
    if params[:fsckspmr] && params[:fsckspmr] == self.class.do_contactar_key
      if user_is_authed
        m = Message.create(:title => params[:subject], :message => params[:message], :user_id_from => @user.id, :user_id_to => User.find(1))
      else
        Notification.deliver_newcontactar(params)
      end
    end
    end

    redirect_to '/site/contactar'
  end

  def album
    @title = "Aquellos maravillosos años"
    @files = Dir.entries("#{RAILS_ROOT}/public/images/history").collect { |e| e if  /thumb\-/ =~ e }.compact.sort
  end

  def fusiones
  end

  def webs_de_clanes
    @title = "Webs para clanes gratis"
  end

  def logo
    @title = "Logo de Gamersmafia"
  end

  def sponsor
    raise ActiveRecord::RecordNotFound unless %w(atlassian fourfrags nls).include?(params[:sponsor])
    render :template => "site/sponsors_#{params[:sponsor]}"
  end

  def carcel
    @title = "Cárcel"
  end

  def ipinfo
    require_auth_users
    raise AccessDenied unless @user.is_hq?
    @ipinfo = Geolocation.ip_info(params[:ip])
    render :layout => false
  end

  def close_content_form
    require_auth_users
    render :layout => false
  end

  def report_content_form
    require_auth_users
    render :layout => false
  end

  def report_comment_form
    require_auth_users
    render :layout => false
  end

  def report_user_form
    require_auth_users
    render :layout => false
  end

  def recommend_to_friend
    require_auth_users
    render :layout => false
  end

  def do_recommend_to_friend
    require_auth_users
    GmSys.job("Content.find(#{params[:content_id].to_i}).recommend_to_friends(User.find(#{@user.id}), [#{params[:friends].join(',')}], '#{params[:comment]}')")
    flash[:notice] = "Recomendación enviada"
    render :partial => '/shared/ajax_facebox_feedback', :layout => false
  end

  def self.do_contactar_key
    MD5.hexdigest((CONTACT_MAGIC + (Time.now.to_i / 3600)).to_s)
  end

  def root_term_children
    raise AccessDenied unless user_is_authed
    @term = Term.find(params[:id])
    render :layout => false
  end
end
