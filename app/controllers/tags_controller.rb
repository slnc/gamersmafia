# -*- encoding : utf-8 -*-
class TagsController < ApplicationController

  def autocomplete
    require_authorization(:can_tag_contents?)
    @out = {}
    if !(/^[a-zA-Z0-9_ -]+$/ =~ params[:text])
      render(:layout => false) && return
    end

    terms = Term.find(
        :all,
        :conditions => "taxonomy = 'ContentsTag'
                        AND LOWER(name) LIKE LOWER(E'#{params[:text]}%')",
        :limit => 100)
    terms.each do |term|
      @out[term.id] = term.name
    end
    render :layout => false
  end

  def index
  end

  def show
    @tag = Term.with_taxonomy("ContentsTag").find_by_slug!(params[:id])
    @title = @tag.name
  end

  def edit
    @tag = Term.with_taxonomy("ContentsTag").find_by_slug!(params[:id])
    @title = @tag.name
  end

  def update
    @tag = Term.with_taxonomy("ContentsTag").find_by_slug!(params[:id])
    if @tag.update_attributes(params[:tag])
      flash[:notice] = "Cambios guardados correctamente"
    else
      flash[:error] = "Error al guardar los cambios: #{@tag.errors.full_messages_html}"
    end
    redirect_to :action => :edit, :id => @tag.slug
  end

  def new
    require_authorization(:can_create_entities?)
    @title = "Nuevo tag"
  end

  def create
    require_authorization(:can_create_entities?)

    uct = UsersContentsTag.new(:original_name => params[:tag][:name])
    if !uct.valid?
      flash[:error] = "Error al crear tag: #{uct.errors.full_messages_html}"
      render(:action => :new) && return
    end

    # TODO(slnc): move this inside decision.rb as a custom validation fn
    content_ids = []
    tag_overlap = {}
    params[:tag][:initial_contents].each do |initial_content|
      content = Content.find_by_url(initial_content)
      next if content.nil?
      content_ids.append(content.id)
      content.terms.contents_tags.find(:all, :order => 'lower(name)').each do |t|
        tag_overlap[t.id] ||= 0
        tag_overlap[t.id] += 1
      end
    end
    content_ids.uniq!
    if content_ids.size < UsersContentsTag::MIN_INITIAL_CONTENTS
      flash[:error] = (
          "Para poder crear un nuevo tag necesitas especificar la url de" +
          " <strong>#{UsersContentsTag::MIN_INITIAL_CONTENTS}</strong>" +
          " contenidos ya publicados en GM a los que aplicarías este tag.")
      render(:action => :new) && return
    end

    params[:tag][:overlaps] = {}
    tag_overlap.each do |term_id, frequency|
      params[:tag][:overlaps][term_id] = (
          frequency.to_f / params[:tag][:initial_contents].size)
    end

    decision = Decision.create({
      :decision_type_class => "CreateTag",
      :context => {
        :tag_name => params[:tag][:name],
        :initial_contents => content_ids,
        :initiating_user_id => @user.id,
        :tag_overlaps => params[:tag][:overlaps],
      },
    })

    if decision.new_record?
      flash[:error] = (
          "Error al crear el tag: #{decision.error.full_messages_html}")
      render :action => :new
    else
      flash[:notice] = (
          "Proceso de creación de tag iniciado. La familia está deliberando.")
      redirect_to(:action => :index) && return
    end
  end
end
