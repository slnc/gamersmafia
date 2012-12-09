# -*- encoding : utf-8 -*-
class ContentLocked < Exception; end

module ActsAsContentBrowser
  def self.included(base)
    base.extend AddActsAsContentBrowser
  end

  module AddActsAsContentBrowser
    def acts_as_content_browser(*args)
      before_filter :require_auth_users,
                    :only => [ :new, :create, :edit, :update, :destroy ]

      class_eval <<-END
        include ActsAsContentBrowser::InstanceMethods
      END

      #verify :method => :post, :only => [ :destroy, :create, :update, :deny ],
      #:redirect_to => '/site/http_401'
    end
  end

  module InstanceMethods
    define_method 'content_name' do
      @_content_name ||= Cms.content_from_controller(ActiveSupport::Inflector::demodulize(self.class.name).gsub('Controller', ''))
    end

    define_method 'index' do
      if @portal.id != -1 && @portal.kind_of?(FactionsPortal)
        @title = "#{ActiveSupport::Inflector::demodulize(self.class.name).gsub('Controller', '')} de #{@portal.name}"
      end
    end

    define_method 'new' do
      @title = "Crear #{Cms::CLASS_NAMES[content_name].downcase}"
      cls = ActiveSupport::Inflector::constantize(ActiveSupport::Inflector::camelize(content_name))
      instance_variable_set("@#{ActiveSupport::Inflector::underscore(content_name)}", cls.new(params[ActiveSupport::Inflector::underscore(content_name)]))
    end

    define_method 'show' do
      _before_show if respond_to?(:_before_show)
      # TODO temp hasta que google reindexe bien
      cls = Object.const_get(content_name) # ActiveSupport::Inflector::constantize(ActiveSupport::Inflector::camelize(content_name))
      #cls = portal.send ActiveSupport::Inflector::underscore(content_name).to_sym # ActiveSupport::Inflector::constantize(ActiveSupport::Inflector::camelize(content_name))
      obj = cls.find(params[:id])
      raise ActiveRecord::RecordNotFound unless obj.is_public? or (user_is_authed and Authorization.can_edit_content?(@user, obj))
      # puts "http://#{request.host}#{request.fullpath} #{obj.url}"
      # puts "http://#{request.host}#{request.fullpath}".index(obj.url)
      Routing.gmurl(obj) if obj.url.nil?
      if "http://#{request.host}#{request.fullpath}".index(obj.url).nil?
        redirect_to(obj.url, :status => 301) and return
      end
      @title = obj.resolve_hid
      # TODO si tiene categoría se la añadimos al navpath
      track_item(obj)
      instance_variable_set("@#{ActiveSupport::Inflector::underscore(content_name)}", obj)
      _after_show if respond_to?(:_after_show)
    end

    define_method 'create' do
      _before_create if respond_to?(:_before_create)

      cls = ActiveSupport::Inflector::constantize(
          ActiveSupport::Inflector::camelize(content_name))
      obj = cls.new(params[ActiveSupport::Inflector::underscore(content_name)])

      obj.user_id = @user.id

      obj.state = case
        when obj.respond_to?(:clan_id) && obj.clan_id
          Cms::PUBLISHED
        when (params[:draft] == '1')
          Cms::DRAFT
        else
          Cms::PENDING
      end

      instance_variable_set(
          "@#{ActiveSupport::Inflector::underscore(content_name)}", obj)
      if Authorization.can_create_content?(@user)
        if obj.respond_to?(:game_id) && params[:root_terms].nil?
          params[:root_terms] = [
              Term.single_toplevel(:game_id => obj.game_id).id]
        end

        # TODO(slnc): hack para coverages
        if (obj.respond_to?(:event_id) && params[:root_terms].nil? &&
            params[:coverage] && params[:coverage][:event_id])
          params[:root_terms] = [
              Event.find_or_404(
                  params[:coverage][:event_id]).main_category.root_id]
        end

        # chequeamos que se haya especificado categoría
        if (Cms::CATEGORIES_TERMS_CONTENTS.include?(content_name) &&
            (!params[:categories_terms] ||
             params[:categories_terms].size == 0 ||
             params[:categories_terms][0].to_i == 0)) ||
            (Cms::ROOT_TERMS_CONTENTS.include?(content_name) &&
             (!params[:root_terms] || params[:root_terms].size == 0 ||
              params[:root_terms][0].to_i == 0))
          flash[:error] = (
            "Debes elegir al menos una categoría para este contenido.")
          render :action => 'new' and return
        end

        if obj.save
          # enlazamos
          proc_terms(obj)
          # TODO lo estamos haciendo en _dos sitios_ ???
          obj.process_wysiwyg_fields
          flash[:notice] = "Contenido de tipo <strong>#{Cms::CLASS_NAMES[cls.name]}</strong> creado correctamente."
          # UsersContentsTag.tag_content(obj, @user, params[:tags], delete_missing=false) if params[:tags]
          if obj.state == Cms::DRAFT
            rediring = Proc.new { redirect_to :action => 'edit', :id => obj.id }
          else
            rediring = Proc.new { redirect_to :action => 'index' }
          end
        else
          flash[:error] = "Error al crear #{Cms::CLASS_NAMES[cls.name]}: #{obj.errors.full_messages_html}"
          render :action => 'new'
        end
      else
        flash[:error] = "Error al crear #{Cms::CLASS_NAMES[cls.name]}: No puedes crear contenidos."
        render :action => 'new'
      end
      _after_create if respond_to?(:_after_create)
      if flash[:error]
        render :action => 'new' unless performed?
      else
        rediring.call
      end
    end

    define_method 'edit' do
      cls = ActiveSupport::Inflector::constantize(ActiveSupport::Inflector::camelize(content_name))
      obj = cls.find(params[:id])
      raise ContentLocked if obj.is_locked_for_user?(@user)
      @title = "Editando #{obj.resolve_hid}"
      navpath2<< [obj.resolve_hid, request.fullpath.gsub('edit', 'show')]
      instance_variable_set("@#{ActiveSupport::Inflector::underscore(content_name)}", obj)
      if Authorization.can_edit_content?(@user, obj) then
        obj.lock(@user)
        render :action => 'edit'
      else
        render :action => 'show'
      end
    end

    define_method 'proc_terms' do |obj|
      if Cms::CATEGORIES_TERMS_CONTENTS.include?(content_name) && params[:categories_terms]
        params[:categories_terms] = [params[:categories_terms]] unless params[:categories_terms].kind_of?(Array)
        params[:categories_terms].collect! { |rtid| rtid.to_i }
        params[:categories_terms] = params[:categories_terms].delete_if { |rtid| rtid < 1 }
        obj.categories_terms_ids = [params[:categories_terms], "#{ActiveSupport::Inflector::pluralize(content_name)}Category"]
      elsif Cms::ROOT_TERMS_CONTENTS.include?(content_name) && params[:root_terms]
        params[:root_terms] = [params[:root_terms]] unless params[:root_terms].kind_of?(Array)
        params[:root_terms].collect! { |rtid| rtid.to_i }
        params[:root_terms] = params[:root_terms].delete_if { |rtid| rtid < 1 }
        obj.root_terms_ids = params[:root_terms]
      end
    end

    define_method 'deny' do
      cls = ActiveSupport::Inflector::constantize(ActiveSupport::Inflector::camelize(content_name))
      obj = cls.find(:first, :conditions => ['id = ? and state = ?', params[:id], Cms::PENDING])
      require_user_can_edit(obj)
      obj.deny(params[:reason], @user)
      flash[:notice] = 'Contenido denegado correctamente'
      redirect_to :action => 'index'
    end

    define_method 'destroy' do
      cls = ActiveSupport::Inflector::constantize(ActiveSupport::Inflector::camelize(content_name))
      obj = cls.find(params[:id])
      require_authorization_for_object(:can_delete_content?, obj)
      Content.delete_content(obj, @user, "Preguntar a #{@user.login}")
      flash[:notice] = 'Contenido enviado a la papelera.'
      redirect_to :action => 'index'
    end

    define_method 'recover' do
      cls = ActiveSupport::Inflector::constantize(ActiveSupport::Inflector::camelize(content_name))
      obj = cls.find(params[:id])
      require_authorization_for_object(:can_recover_content?, obj)
      Content.recover_content(obj, @user)
      flash[:notice] = 'Contenido recuperado de la papelera correctamente'
      redirect_to :action => 'show', :id => obj.id
    end

    define_method 'update' do
      _before_update if respond_to?(:_before_update)
      cls = ActiveSupport::Inflector::constantize(ActiveSupport::Inflector::camelize(content_name))
      obj = cls.find(params[:id])
      obj.cur_editor = @user
      require_user_can_edit(obj)
      raise ContentLocked if obj.is_locked_for_user?(@user)
      obj.state = Cms::PENDING if obj.state == Cms::DRAFT and params[:draft].to_s != '1'
      params[ActiveSupport::Inflector::underscore(content_name)][:state] = obj.state
      instance_variable_set("@#{ActiveSupport::Inflector::underscore(content_name)}", obj)
      if obj.update_attributes(params[ActiveSupport::Inflector::underscore(content_name)])
        proc_terms(obj)
        # obj.process_wysiwyg_fields
        if !flash[:error]
          flash[:notice] = (
              "#{Cms::CLASS_NAMES[cls.name]} actualizado correctamente.")
        end

        if obj.state == Cms::PUBLISHED then
          redirect_to gmurl(obj)
        else
          redirect_to :action => 'edit', :id => obj.id
        end
      else
        flash.now[:error] = "Error al actualizar #{Cms::CLASS_NAMES[cls.name]}: #{obj.errors.full_messages_html}"
        redirect_to :action => 'edit', :id => obj.id
      end
      _after_update if respond_to?(:_after_update)
    end

    define_method 'reopen' do
      cls = ActiveSupport::Inflector::constantize(ActiveSupport::Inflector::camelize(content_name))
      obj = cls.find(params[:id])
      require_user_can_edit(obj)

      obj.reopen(@user) if obj.closed?

      flash[:notice] = "#{Cms::CLASS_NAMES[cls.name]} reabierto a comentarios."
      redirect_to gmurl(obj)
    end
  end
end

ActionController::Base.send(:include, ActsAsContentBrowser)
