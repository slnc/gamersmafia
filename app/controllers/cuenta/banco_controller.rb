# -*- encoding : utf-8 -*-
class Cuenta::BancoController < ApplicationController

  VALID_CLASSES = %(User Clan Faction)

  before_filter do |c|
    if !user_is_authed || !Authorization.can_access_bank?(c.user)
      raise AccessDenied
    end
  end

  def index
    @navpath = [['Preferencias', '/cuenta'], ['Banco', '/cuenta/banco']]
  end

  def confirmar_transferencia
    params[:redirto] ||= '/'

    if params[:recipient_class] == "Clan" && params[:recipient_clan_name]
      recipient = Clan.find_by_name(params[:recipient_clan_name])
      if recipient.nil?
        flash[:error] = 'No se ha encontrado el clan especificado.'
        redirect_to(params[:redirto]) && return
      else
        params[:recipient_id] = recipient.id
      end
    elsif params[:recipient_class] == "User" && params[:recipient_user_login]
      recipient = User.find_by_login(params[:recipient_user_login])
      if recipient.nil?
        flash[:error] = 'No se ha encontrado el usuario especificado.'
        redirect_to(params[:redirto]) && return
      else
        params[:recipient_id] = recipient.id
      end
    else
      recipient = self.get_party(
          params[:recipient_class], params[:recipient_id])
    end

    sender = self.get_party(params[:sender_class], params[:sender_id])
    errors = self.transfer_errors(sender, recipient)

    @title = 'Confirmar transferencia'
    if errors.size > 0
      flash[:error] = "<ul><li>#{errors.join("<li>,</li>")}</li></ul>"
      redirect_to(params[:redirto])
    end
    @recipient = recipient
    @sender = sender
  end

  def transferencia_confirmada
    sender = self.get_party(params[:sender_class], params[:sender_id])
    recipient = self.get_party(params[:recipient_class], params[:recipient_id])
    errors = self.transfer_errors(sender, recipient)

    if errors.size > 0
      flash[:error] = "<ul><li>#{errors.join("<li>,</li>")}</li></ul>"
      redirect_to(params[:redirto])
    else
      Bank.transfer(
          sender, recipient, params[:ammount].to_f, params[:description])
      flash[:notice] = 'Transferencia realizada correctamente.'
      redirect_to(params[:redirto])
    end
  end

  protected
  # Determines which errors (if any) are present in params representing a bank
  # transfer.
  def transfer_errors(sender, recipient)
    errors = []
    if sender.id != @user.id
      errors << 'No puedes realizar transferencias en nombre de otro usuario.'
    end

    if recipient.nil?
      errors << 'No se ha encontrado al destinatario.'
    end

    if sender.class.name == recipient.class.name && sender.id == recipient.id
      errors << 'El destinatario debe ser distinto del remitente.'
    end

    if params[:description].to_s.strip == ''
      errors << 'La descripción no puede estar en blanco.'
    end

    if (params[:ammount].to_f < 0 ||
        sender.cash < 0 ||
        sender.cash < params[:ammount].to_f)
      errors << 'No tienes el dinero suficiente para hacer esa transferencia'
    end

    case sender.class.name
      when 'Clan'
        errors << "Solo líderes de clan pueden efectuar transferencias."
      when 'Competition'
        errors << ("Solo administradores de competiciones pueden efectuar
                    transferencias.")
      when 'Faction'
        errors << ("Solo bosses pueden pueden efectuar transferencias.")
    end

    if (recipient.class.name == 'User' &&
        !Authorization.can_access_bank?(recipient))
      errors << "El destinatario todavía no tiene la habilidad de recibir
                 transferencias."
    end

    errors
  end

  def get_party(recipient_class, recipient_id)
    if recipient_class.to_s == "" || !VALID_CLASSES.include?(recipient_class)
      raise ActiveRecord::RecordNotFound
    end
    Object.const_get(recipient_class.to_sym).find_by_id(recipient_id)
  end

end
