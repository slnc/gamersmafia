class Cuenta::MensajesController < ApplicationController
  before_filter :require_auth_users
  
  def submenu
    'Mensajes'
  end
  
  def submenu_items
    [['Mensajes recibidos', '/cuenta/mensajes'],
    ['Mensajes enviados', '/cuenta/mensajes/mensajes_enviados'],]
  end
  
  def mensajes
    # TODO debe tener su propio controller
    @navpath = [['Preferencias', '/cuenta'], ['Mensajes', '/cuenta/mensajes']]
    @messages = Message.paginate(:conditions => "user_id_to = #{@user.id} and receiver_deleted is false", :order => 'messages.created_on DESC', :include => [:sender], :page => params[:page], :per_page => 30)
    @title = 'Mensajes recibidos'
    @highlighted_user = :sender
    @message = Message.new
  end
  
  def mensajes_enviados
    # TODO debe tener su propio controller
    @navpath = [['Preferencias', '/cuenta'], ['Mensajes', '/cuenta/mensajes']]
    @title = 'Mensajes enviados'
    @message = Message.new
    @highlighted_user = :recipient
    @messages = Message.paginate(:conditions => "user_id_from = #{@user.id} and sender_deleted is false", :order => 'created_on DESC', :page => params[:page], :per_page => 30)
    render :action => 'mensajes'
  end
  
  def new
    @curuser = User.find(params[:id])
    render :layout => false
  end
  
  
  def create_message
    @title = 'Mensajes'
    @message = Message.new
    @messages = Message.paginate(:conditions => "user_id_to = #{@user.id} and receiver_deleted is false", :order => 'messages.created_on DESC', :include => [:sender], :page => params[:page], :per_page => 30)
    recipient = User.find_by_login(params[:message][:recipient])
    
    if params[:redirto].to_s == '' then
      params[:redirto] = '/cuenta/mensajes'
    end
    
    # Check recipient
    case params[:message][:message_type].to_i
      when Message::R_USER:
      u = User.find_by_login(params[:message][:recipient_user_login])
      if u.nil?
        flash[:error] = "El usuario especificado no existe."
        redirect_to params[:redirto] and return false
      elsif !User::STATES_CAN_LOGIN.include?(u.state)
        flash[:error] = "El usuario especificado existe pero su cuenta no está disponible."
        redirect_to params[:redirto] and return false
      end
      recipients = [u.id]
      # no check
      when Message::R_CLAN:
      if params[:message][:recipient_clan_id].nil?
        params[:message][:recipient_clan_id] = @user.last_clan_id
      end
      
      if params[:message][:recipient_clan_id].nil?
        flash[:error] = "No se ha encontrado el clan especificado."
        redirect_to params[:redirto] and return false
      end
      
      c = Clan.find(params[:message][:recipient_clan_id])
      raise ActiveRecord::RecordNotFound unless c && c.user_is_member(@user.id)
      recipients = c.all_users_of_this_clan.collect { |u| u.id }
      when Message::R_FACTION:
      f = @user.faction
      raise ActiveRecord::RecordNotFound unless f.is_bigboss?(@user)
      recipients = f.members.collect { |u| u.id }
      when Message::R_FACTION_STAFF:
      f = @user.faction
      raise ActiveRecord::RecordNotFound unless f.is_bigboss?(@user)
      recipients = []
      recipients += f.moderators.collect { |u| u.id}
      recipients += f.editors.collect { |content_type, u| u.id }
      recipients<< f.boss.id if f.has_boss? && f.boss.id != @user.id
      recipients<< f.underboss.id if f.has_underboss? && f.underboss.id != @user.id
      when Message::R_FRIENDS:
      recipients = @user.friends.collect { |u| u.id }
    end
    params[:message][:user_id_from] = @user.id
    params[:message].delete(:recipient_clan_id)
    params[:message].delete(:recipient_user_login)
    
    recipients.uniq.each do |uid|
      params[:message][:user_id_to] = uid
      Message.create(params[:message])
    end
    
    flash[:notice] = 'Mensaje enviado correctamente.'
    if params[:ajax]
      render :partial => '/shared/ajax_facebox_feedback', :layout => false
    else
      if flash[:error]
        render :action => :new
      else
        redirect_to params[:redirto]
      end
    end
  end
  
  def mensaje
    @curmessage = Message.find(:first, :conditions => ['id = ? and (user_id_to = ? or user_id_from = ?)', params[:id], @user.id, @user.id])
    raise ActiveRecord::RecordNotFound unless @curmessage
    @message = Message.new
    @curmessage.read(@user) if @user.id == @curmessage.user_id_to
    @navpath = [['Cuenta', '/cuenta'], ['Mensajes', '/cuenta/mensajes'], [@curmessage.title, "/cuenta/mensajes/mensaje/#{@curmessage.id}"]]
    @title = @curmessage.title
  end
  
  
  def del_messages
    if params[:messages] then
      for mid in params[:messages]
        msg = Message.find(mid.to_i)
        if msg.recipient == @user then
          msg.delete_from_recipient
        elsif msg.sender == @user then
          msg.delete_from_sender
        end
      end
      flash[:notice] = 'Mensajes borrados correctamente.'
    end
    
    redirect_to params[:redirto] || '/cuenta/mensajes'
  end
end
