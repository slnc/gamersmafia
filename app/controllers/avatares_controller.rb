# -*- encoding : utf-8 -*-
class AvataresController < ApplicationController
  require_admin_permission :capo

  def index
  end

  def list
    @title = "Índice de avatares de #{params[:mode]}"
    raise ActiveRecord::RecordNotFound unless %w(faction clan user).include?(params[:mode])
  end

  def faction
    @faction = Faction.find(params[:id])
  end

  def new

    @avatar = Avatar.new({:faction_id => ''})
  end

  def create_from_zip
    # descomprimimos archivo
    # workdir is ~/tmp/avatares

    # TODO dirty
    tmp_dir = "#{Dir.tmpdir}/#{Kernel.rand.to_s}"
    Dir.mkdir(tmp_dir)

    # iteramos a través de cada directorio-juego
    system("unzip -q #{params[:avatar].path} -d \"#{tmp_dir}\"")

    # estructura del zip
    # /tmp/avatars/nombre_zip
    #                        /aa
    #                        /ut
    #                        /*

    d1 = Dir.open("#{tmp_dir}/#{params[:avatar].original_filename.gsub(/.zip/, '')}")

    for d1_faction in d1.entries
      next if d1_faction == '.' or d1_faction ==  '..'
      #ogame = Game.find(:first, :conditions => ['lower(code) = ?', d1_faction])
      #if not ogame
      #  flash[:error] = "Juego con código #{d1_faction} no encontrado"
      #  next
      #end

      faction = Faction.find(:first, :conditions => ['lower(code) = ?', d1_faction])
      if not faction
        flash[:error] = "Facción con codigo #{d1_faction} no encontrada"
        next
      end

      # entramos en dir de facción
      d2 = Dir.open("#{d1.path}/#{d1_faction}")
      i = 0
      for d2_level in d2.entries
        next if d2_level == '.' or d2_level ==  '..'
        d3 = Dir.open("#{d2.path}/#{d2_level}")
        for d3_avatar in d3.entries
          next if d3_avatar == '.' or d3_avatar ==  '..'
          avatar_name = d3_avatar.gsub(/\.jpg/, '')
          # existe?
          avatar = faction.avatars.find(:first, :conditions => ['name = ?', avatar_name])
          f = File.open("#{d3.path}/#{avatar_name}.jpg")
          if not avatar then
            avatar = faction.avatars.new({:name => avatar_name, :faction_id => faction.id, :level => d2_level, :path => f, :submitter_user_id => @user.id})
            avatar.save
          else
            # TODO deberíamos borrar los avatares que ya no estén
            avatar.path = f
            avatar.save
            # raise 'avatar exists!'
          end
          i += 1
          f.close
        end
      end
    end

    d1.close
    system("rm -r #{tmp_dir}")
    flash[:notice] = "<strong>#{i}</strong> avatares creados correctamente."
    redirect_to :action => 'new'
  end

  def create

    @avatar = Avatar.new(params[:avatar].merge({:submitter_user_id => @user.id}))
    if @avatar.save
      flash[:notice] = 'Avatar creado correctamente.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit

    @avatar = Avatar.find(params[:id])
  end

  def update

    @avatar = Avatar.find(params[:id])
    if @avatar.update_attributes(params[:avatar])
      flash[:notice] = 'Avatar actualizado correctamente.'
      redirect_to :action => 'edit', :id => @avatar
    else
      render :action => 'edit'
    end
  end

  def destroy(returning = false)
    a = Avatar.find(params[:id])
    if a.destroy(returning)
      flash[:notice] = "Avatar borrado correctamente"
      redirect_to :action => 'list', :mode => a.mode
    else
      flash[:error] = "Ocurrió un error al borrar el avatar:<br />#{a.errors.full_messages_html}"
      edit
      render :action => 'edit'
    end
  end

  def destroy_returning
    destroy(true)
  end

  def factions_avatars_overview
    @title = "Resumen de avatares de facción"
  end
end
