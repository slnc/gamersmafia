class Cuenta::GuidsController < ApplicationController
  before_filter :require_auth_users
  @@navpath_base = ['GUIDs', '/guids']

  def index
    @title = 'GUIDs'
  end

  def guardar
    flash[:error] = ''
    flash[:notice] = ''
    for g in Game.find(:all, 'has_guids = \'t\'')
      if g.has_guids?
        f_field = "guid#{g.id}".to_sym 
        params[f_field][:game_id] = g.id
        params[f_field][:user_id] = @user.id
        last_guid = @user.users_guids.find_last(@user, g)
        # TODO añadir formato/validación de GUIDs
        if (not params[f_field][:guid].blank?) and (not (last_guid && last_guid.guid == params[f_field][:guid])) then # si ha cambiado guardamos
          if not last_guid then
            params[f_field][:reason] = 'GUID inicial'
          end

          if params[f_field][:reason].to_s == '' then
            flash[:error] << "No has especificado una razón para cambiar tu GUID de #{g.name}.<br />"
          else
            params[f_field][:reason].strip
            new_ug = @user.users_guids.new(params[f_field])
            if new_ug.save then
              params[:games] ||= []
              params[:games]<< new_ug.game_id.to_s
              flash[:notice] << "GUID de #{g.name} guardado correctamente<br />"
            else
              flash[:error] << "(#{g.name}) " << new_ug.errors.full_messages.join('<br />') << '<br />'
            end
          end
        end  
      end # has_guids
    end # for

    @user.game_ids = params[:games] ? params[:games].uniq : []

    flash[:error] = nil if flash[:error] == ''
    flash[:notice] = nil if flash[:notice] == ''

    redirect_to :action => 'index'
  end
end
