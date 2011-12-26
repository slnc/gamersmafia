require 'net/imap'

class Notification < ActionMailer::Base
  def deliver!
    val = super
    # :body => self.mail.body,
    SentEmail.create(:message_key => @message_key,
      :recipient => @recipients,
      :recipient_user_id => @recipient_user_id,
      :sender => @from,
      :title => @subject 
    )
    val
  end
  
  def self.controller_path
    ''
  end
  
  def gmurl(object)
    Routing.gmurl(object)
  end
  
  def setup(recipients, vars={})
    
    ActionView::Base.send :include, ApplicationHelper
    raise Exception unless vars.kind_of? Hash
    vars = { :available_actions => [], :base_url => 'http://gamersmafia.com' }.merge(vars)
    
    if vars[:sender] && vars[:sender].class.name != 'User'
      raise "Sender is #{vars[:sender].class.name} but can only be User"
    elsif !vars[:sender]
      vars[:sender] = User.find_by_login('nagato') 
    end
    
    #{ :sender =>  }.merge
    @recipients =  ''
    case recipients.class.name
      when 'User':
      @recipients << "#{recipients.login} <#{recipients.email}>"
      vars[:sl] = sl(recipients)
      vars[:recipient] = recipients
      when 'Friend':
      @recipients << "#{recipients.login} <#{recipients.email}>"
      vars[:sl] = sl(recipients)
      vars[:recipient] = recipients
      when 'Clan':
      recipients.admins.each { |user| @recipients << "#{user.login} <#{user.email}>, " }
      when 'String':
      @recipients<< '<'<< recipients << '>'
    else
      raise 'unimplemented'
    end
    
    # TODO enviar emails con multipart en formato html y text
    #vars = {"#{vars.class.name.downcase}".to_sym => vars} unless vars.kind_of?(Hash)
    #vars.merge!({ :footer => "Administrador de Gamersmafia\ngamersmafia.com", :base_url => 'http://gamersmafia.com/' })
    @subject = '[gm] ' << vars[:title].to_s
    @sent_on = Time.now
    
    vars[:sent_on] = @sent_on
    @body = vars
    if recipients.class.name == 'User'
      @recipient_user_id = recipients.id
    end
    @message_key = Digest::MD5.hexdigest(Time.now.to_i.to_s + (recipients.class.name == 'User' ? recipients.validkey : @recipients.to_s) + @subject)
    @from = "#{vars[:sender].login} <#{App.system_mail_user.split('@')[0]}@gamersmafia.com>"
    @headers = {'gmmid' => @message_key, 'Return-Path' => "#{App.system_mail_user.split('@')[0]}-#{@message_key}@gamersmafia.com"}
    @return_path ="#{App.system_mail_user.split('@')[0]}-#{@message_key}@gamersmafia.com"
    vars[:message_key] = @message_key
    #attachment :content_type => 'image/png', :body => File.read("#{RAILS_ROOT}/public/images/emails/gm.png")
    #attachment :content_type => 'image/png', :body => File.read("#{RAILS_ROOT}/public/images/emails/footer-bg.png")
  end
  
  # keys: prod, support (both are Time's) 
  def support_db_oos(vars)
    vars.merge!({ :actions => [],
      :title => "DB Support Out Of Sync"})
    setup(User.find(1), vars)
  end
  
  # keys: new_member
  def add_to_hq(user, vars)
    vars.merge!({ :actions => [],
      :title => "Añadir a #{vars[:new_member].login} a la lista de correo"})
    setup(user, vars)
  end
  
  def yourebanned(user, vars)
    vars = {}
    vars.merge!({ :actions => [],
      :title => "Tu cuenta ha sido baneada"})
    setup(user, vars)
  end
  
  
  # keys: 
  def new_factions_banned_user(user, vars)
    vars.merge!({ :actions => [["Ir a la ficha de #{vars[:factions_ban].user.login}", "#{gmurl(vars[:factions_ban].user)}"], 
      ['Editar usuario en admin', "/admin/usuarios/edit/#{vars[:factions_ban].user_id}"]],
      :title => "Usuario #{vars[:factions_ban].user.login} baneado de #{vars[:factions_ban].faction.name}"})
    setup(user, vars)
  end
  
  # keys: faction
  def faction_summary(user, vars)
    vars.merge!({ :actions => [['Ir a la portada de mi facción', "#{gmurl(Faction.find(vars[:faction].id))}"], 
      ['Ir a la admin de facciones', '/cuenta/faccion']],
      :title => "Informe semanal sobre #{vars[:faction].code.upcase} - #{Time.now.strftime('%d %b, %Y')}"})
    setup(user, vars)
  end
  
  # keys: 
  def del_from_hq(user)
    vars = {}
    vars.merge!({ :actions => [],
      :title => "Eliminar a #{user.login} del HQ"})
    setup(user, vars)
  end
  
  # keys: message
  def newmessage(user, vars)
    vars.merge!({ :actions => [
      ['Ir a tu buzón de mensajes', '/cuenta/mensajes'],],
      :title => vars[:message].title})
    setup(user, vars)
  end
  
  
  # keys: signer
  def newprofilesignature(user, vars)
    acts = [['Enviarle un mensaje', "/cuenta/mensajes#{sl(user)}"],
    ['Ir a mi libro de firmas', "#{gmurl(user)}/firmas"]]
    
    if vars[:signer].enable_profile_signatures?
      acts<< ['Firmar en su libro', "#{gmurl(vars[:signer])}/firmas"]
    end
    
    vars.merge!({ :actions => acts,
      :title => "Tienes una nueva firma en tu perfil"})
    setup(user, vars)
  end
  
  # keys: competition
  def competition_started(user, vars)
    vars.merge!({ :actions => [['Ir a la competición', "/competiciones/show/#{vars[:competition].id}#{sl(user)}"],
      ["Ir a mis partidas", "/cuenta/competiciones#{sl(user)}"],
      ["Resto de participantes", "/competiciones/show/#{vars[:competition].id}/participantes#{sl(user)}"]],
      :title => "Comienza la #{vars[:competition].name}"})
    setup(user, vars)
  end
  
  # no lo aplicamos a todos los links por seguridad
  def sl(u)
    u.kind_of?(User) ? "?vk=#{u.validkey}" : ''
  end
  
  def welcome(user, vars={})
    vars.merge!({ :actions => [['Personalizar tu perfil', "/cuenta/perfil#{sl(user)}"],
      ['Unirme a una facción', "/cuenta/faccion#{sl(user)}"],
      ['Publicar entradas en tu blog', "/cuenta/blog#{sl(user)}"],
      ['Ir a los foros', "/foros#{sl(user)}"],
      ['Crear un clan', "/cuenta/clanes#{sl(user)}"],
      ['Crear una competición', "/cuenta/competiciones#{sl(user)}"],
      ],
      :title => 'Bienvenido a gamersmafia'})
    setup(user, vars)
  end
  
  
  def forgot(user, vars={})
    vars.merge!({ :actions => [['Resetear contraseña', "/cuenta/reset/?k=#{user.validkey}&login=#{user.login}"],],
      :title => 'Resetear tu contraseña'})
    setup(user, vars)
  end
  
  
  def signup(user, vars={})
    confirm_url = "/cuenta/do_confirmar?k=#{user.validkey}&email=#{user.email}"
    
    vars.merge!({ :actions => [['Confirmar tu nueva cuenta', confirm_url],],
      :title => "Confirma tu nueva cuenta #{user.login}",
      :confirm_url => confirm_url })
    setup(user, vars)
  end
  
  def emailchange (user)
    vars = ({ :actions => [['Confirmar cambio de contraseña', "/cuenta/do_change_email?k=#{user.validkey}&email=#{user.email}"],],
      :title => 'Confirma el cambio de dirección de email',
      :old_email => user.email})
    user.email = user.newemail
    setup(user, vars)
  end
  
  def newregistration(user, vars)
    actions = []
    actions<< ["Añadir a #{vars[:refered].login} a mi lista de amigos", "/cuenta/cuenta/add_refered#{sl(user)}&login=#{vars[:refered].login}"] if not vars[:refered].is_friend_of?(user)
    actions<< ["Ir a la ficha de #{vars[:refered].login}", "#{gmurl(vars[:refered])}#{sl(user)}"]
    actions<< ['Ir a mis estadísticas de usuarios referidos', "/cuenta/estadisticas/registros#{sl(user)}"]
    vars.merge!({ :actions => actions,
      :title => "Nuevo usuario referido: #{vars[:refered].login}"})
    setup(user, vars)
  end
  
  def resurrection(user, vars)
    vars.merge!({ :actions => [["Ir a la ficha de #{vars[:resurrected].login}", "#{gmurl(vars[:resurrected])}#{sl(user)}"],
      ['Ir a mis estadísticas de usuarios resucitados', "/cuenta/estadisticas/resurrecciones#{sl(user)}"]],
      :title => "Has resucitado a #{vars[:resurrected].login}" })
    setup(user, vars)
  end
  
  def unconfirmed_1w(user, vars={})
    vars.merge!({ :actions => [['Confirmar tu nueva cuenta', "/cuenta/do_confirmar?k=#{user.validkey}&email=#{user.email}"]],
      :title => "Tu cuenta aún no está confirmada" })
    setup(user, vars)
  end
  
  def unconfirmed_2w(user, vars={})
    vars.merge!({ :actions => [['Confirmar tu nueva cuenta', "/cuenta/do_confirmar?k=#{user.validkey}&email=#{user.email}"]],
      :title => "Tu cuenta aún no está confirmada" })
    setup(user, vars)
  end
  
  def trackerupdate(user, vars)
    vars.merge!({ :actions => [[vars[:content].resolve_hid, Routing.url_for_content_onlyurl(vars[:content])],
      ['Ir a mi tracker', "/cuenta/cuenta/tracker#{sl(user)}"],],
      :title => "Nuevos comentarios en #{vars[:content].resolve_hid}"})
    setup(user, vars)
  end
  
  
  def rechallenge(user, vars)
    vars.merge!({ :actions => [["Ir a la ficha de #{vars[:participant].name}", "/competiciones/participante/#{vars[:participant].id}#{sl(user)}"],
      ['Ir a la competición', "/competiciones/show/#{vars[:participant].competition_id}#{sl(user)}"],
      ['Ir a mis partidas', "/cuenta/competiciones#{sl(user)}"]],
      :title => "#{vars[:participant].name} te ha lanzado un contrarreto"})
    setup(user, vars)
  end
  
  
  def reto_recibido(user, vars)
    vars.merge!({ :actions => [["Ir a la ficha de #{vars[:participant].name}", "/competiciones/participante/#{vars[:participant].id}#{sl(user)}"],
      ['Ir a la competición', "/competiciones/show/#{vars[:participant].competition_id}#{sl(user)}"],
      ['Ir a mis partidas', "/cuenta/competiciones#{sl(user)}"]],
      :title => "#{vars[:participant].name} te ha retado"})
    setup(user, vars)
  end
  
  def reto_pendiente_1w(user, vars)
    vars.merge!({ :actions => [["Ir a la ficha de #{vars[:participant].name}", "/competiciones/participante/#{vars[:participant].id}#{sl(user)}"],
      ['Ir a la competición', "/competiciones/show/#{vars[:participant].competition_id}#{sl(user)}"],
      ['Ir a mis partidas', "/cuenta/competiciones#{sl(user)}"]],
      :title => "El reto de #{vars[:participant].name} está esperando tu respuesta"})
    setup(user, vars)
  end
  
  def reto_pendiente_2w(user, vars)
    vars.merge!({ :actions => [["Ir a la ficha de #{vars[:participant].name}", "/competiciones/participante/#{vars[:participant].id}#{sl(user)}"],
      ['Ir a la competición', "/competiciones/show/#{vars[:participant].competition_id}#{sl(user)}"],
      ['Ir a mis partidas', "/cuenta/competiciones#{sl(user)}"]],
      :title => "El reto de #{vars[:participant].name} se cancelará pronto"})
    setup(user, vars)
  end
  
  def reto_cancelado_sin_respuesta(user, vars)
    vars.merge!({ :actions => [["Ir a la ficha de #{vars[:participant].name}", "/competiciones/participante/#{vars[:participant].id}#{sl(user)}"],
      ['Ir a la competición', "/competiciones/show/#{vars[:participant].competition_id}#{sl(user)}"],
      ['Ir a mis partidas', "/cuenta/competiciones#{sl(user)}"]],
      :title => "El reto de #{vars[:participant].name} se ha cancelado automáticamente"})
    setup(user, vars)
  end
  
  def reto_aceptado(user, vars)
    vars.merge!({ :actions => [["Ir a la ficha de #{vars[:participant].name}", "/competiciones/participante/#{vars[:participant].id}#{sl(user)}#{sl(user)}"],
      ['Ir a la competición', "/competiciones/show/#{vars[:participant].competition_id}#{sl(user)}"],
      ['Ir a mis partidas', "/cuenta/competiciones#{sl(user)}"]],
      :title => "Reto aceptado por #{vars[:participant].name}"})
    setup(user, vars)
  end
  
  def reto_rechazado(user, vars)
    vars.merge!({ :actions => [["Ir a la ficha de #{vars[:participant].name}", "/competiciones/participante/#{vars[:participant].id}#{sl(user)}"],
      ['Ir a la competición', "/competiciones/show/#{vars[:participant].competition_id}#{sl(user)}"],
      ['Ir a mis partidas', "/cuenta/competiciones#{sl(user)}"]],
      :title => "Reto rechazado por #{vars[:participant].name}"})
    setup(user, vars)
  end
  
  
  def invited_participant(user, vars)
    vars.merge!({ :actions => [
      ['Ir a la competición', "/competiciones/show/#{vars[:competition].id}#{sl(user)}"],
      ],
      :title => "Has sido invitado a la competición #{vars[:competition].name}"})
    setup(user, vars)
  end
  
  
  def ad_report(advertiser, vars)
    raise 'undefined tstart' unless vars.has_key?(:tstart)
    raise 'undefined tend' unless vars.has_key?(:tend)
    #ENV['TSTART'] = vars[:tstart]
    #ENV['TEND'] = vars[:tend]
    #ENV['PUBLISHER'] = advertiser.name
    # output = Rake::Task['gm:ad_report:piped'].invoke
    
    #ENV.delete 'TSTART'
    #ENV.delete 'TEND'
    #ENV.delete 'PUBLISHER'
    @bcc = 'slnc@gamersmafia.com'
    
    vars.merge!({:actions => [],
      :advertiser => advertiser, 
      :meine_output => ENV['REPORT_OUTPUT'], 
      :title => "Informe de visitas del #{vars[:tstart].strftime('%Y-%m-%d')} al #{vars[:tend].strftime('%Y-%m-%d')}"})
    #ENV.delete 'REPORT_OUTPUT'
    setup(advertiser.email, vars)
  end
  
  def weekly_avg_page_render_time(vars)
    vars.merge!({:actions => [], 
      :title => "Informe de tiempo de render de los últimos 7 días"})
    setup('slnc@gamersmafia.com', vars)
  end
  
  # keys: subject, user, email, message
  def newcontactar(vars)
    vars[:sender] = User.new(:login => vars[:email], :email => vars[:email])
    vars.merge!({ :actions => [
      ],
      :title => vars[:subject].strip})
    setup(User.find(1), vars)
  end
  
  def new_friendship_request(user, vars)
    @name = user.kind_of?(User) ? user.login : user.gsub(/@(.+)/, '')
    vars.merge!({ :actions => [['Aceptar amistad', "/cuenta/amigos/aceptar_amistad/#{vars[:sender].login}#{sl(user)}"],
        ['Rechazar amistad', "/cuenta/amigos/cancelar_amistad/#{vars[:sender].login}#{sl(user)}"],
        ["Ir a la ficha de #{vars[:sender].login}", "#{gmurl(vars[:sender])}#{sl(user)}"]
      ],
      :title => "#{vars[:sender].login} quiere ser tu amigo"})
    setup(user, vars)
    @from = vars[:from] if vars[:from]
  end
  
  def new_friendship_request_external(user, vars)
    @invitation_key = vars[:invitation_key]
    @name = user.kind_of?(User) ? user.login : user.gsub(/@(.+)/, '')
    vars.merge!({ :actions => [['Aceptar amistad', "/cuenta/amigos/aceptar_amistad/?eik=#{@invitation_key}"],
        ['Rechazar amistad', "/cuenta/amigos/cancelar_amistad/?eik=#{@invitation_key}"],
        ["Ir a la ficha de #{vars[:sender].login}", "#{gmurl(vars[:sender])}#{sl(user)}"],
        ["No recibir más invitaciones", "/cuenta/amigos/colvidadme/?eik=#{@invitation_key}"]
      ],
      :title => "#{vars[:sender].login} quiere ser tu amigo"})
    setup(user, vars)
    #@from = vars[:from] if vars[:from]
    
  end
  
  def new_friendship_accepted(user, vars)
    actions = []
    actions<< ['Invitar a más amigos', "/cuenta/amigos#{sl(user)}"]
    actions<< ["Ir a la ficha de #{vars[:receiver].login}", "#{gmurl(vars[:receiver])}#{sl(user)}"]
    vars.merge!({ :actions => actions,
      :title => "#{vars[:receiver].login} ha aceptado tu amistad"})
      setup(user, vars)
  end
end
