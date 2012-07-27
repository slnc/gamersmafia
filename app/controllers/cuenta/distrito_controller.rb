# -*- encoding : utf-8 -*-
class Cuenta::DistritoController < ApplicationController
  before_filter :require_user_is_don_or_mano_derecha

  def submenu
    'Distrito'
  end

  def submenu_items
    l = []

    l<<['Staff', '/cuenta/distrito/staff']
    l<<['Categorías de contenidos', '/cuenta/distrito/categorias']

    l
  end

  def index
  end

  def add_sicario
    if params[:login].to_s != ''
      thenew = User.find_by_login(params[:login])
      if thenew.nil?
        flash[:error] = "No se ha encontrado a ningun usuario con el nick <strong>#{params[:login]}</strong>"
        redirect_to '/cuenta/distrito' and return
      end
    end
    @cur_district.add_sicario(thenew)
    flash[:notice] = "Añadido <strong>#{params[:login]}</strong> como sicario de <strong>#{@cur_district.name}</strong>"
    redirect_to '/cuenta/distrito'
  end

  def del_sicario
    u = User.find(params[:user_id].to_i)
    @cur_district.del_sicario(u)
    flash[:notice] = "<strong>#{u.login}</strong> ha dejado de ser sicario de <strong>#{@cur_district.name}</strong>"
    redirect_to '/cuenta/distrito'
  end

  def update_mano_derecha
    raise AccessDenied if @user_status_in_district != 'Don'
    if params[:login].to_s != ''
      thenew = User.find_by_login(params[:login])
      if thenew.nil?
        flash[:error] = "No se ha encontrado a ningun usuario con el nick <strong>#{params[:login]}</strong>"
        redirect_to '/cuenta/distrito' and return
      end
       (redirect_to '/cuenta/distrito' and return) if @cur_district.mano_derecha && @cur_district.mano_derecha.id == thenew.id
      if thenew.users_skills.count(:conditions => ['role IN (?)', %w(Don ManoDerecha)]) > 0
        flash[:error] = "<strong>#{thenew.login}</strong> ya es don o mano derecha de otro distrito. Debe dejar su cargo actual antes de poder añadirlo como Mano Derecha de <strong>#{@cur_district.name}</strong>"
        redirect_to '/cuenta/distrito' and return
      end
      flash[:notice] = "Mano Derecha <strong>#{params[:login]}</strong> guardada correctamente"
    else
      thenew = nil
      flash[:notice] = "Mano Derecha eliminada correctamente."
    end
    @cur_district.update_mano_derecha(thenew)
    redirect_to '/cuenta/distrito'
  end

  def get_cls(type_name)
    Cms.category_class_from_content_name(type_name)
  end

  protected
  def require_user_is_don_or_mano_derecha
    require_auth_users
    ur = @user.users_skills.find(:first, :conditions => ['role IN (?)', %w(Don ManoDerecha)])
    raise AccessDenied unless ur
    @user_status_in_district = ur.role
    @cur_district = BazarDistrict.find(ur.role_data.to_i)
  end
end
