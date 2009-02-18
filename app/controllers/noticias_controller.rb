class NoticiasController < InformacionController
  NEWS_PER_PAGE = 20
  acts_as_content_browser :news
  allowed_portals [:gm, :faction, :clan, :bazar, :bazar_district]
  
  def second_level_categories
    headers['content-type'] = 'text/javascript'
    @categories = NewsCategory.find(params[:id]).children.find(:all, :order => 'lower(name)')
    render :layout => false
  end
  
  def _before_create
    parse_subcat_thing('new')
  end
  
  def _before_update
    parse_subcat_thing('new')
  end
  
  
  def parse_subcat_thing(orig_action)
    if params[:new_subcategory_name].to_s != '' then
      # TODO search existing subcategory
      nc = NewsCategory.find(params[:news][:news_category_id])
      new_child = nc.children.create({:name => params[:new_subcategory_name], :file => params[:new_subcategory_file]})
      if new_child.new_record?
        flash[:error] = "Error al crear la nueva categoría secundaria:<br />#{new_child.errors.full_messages_html}"
        render :action => orig_action
        return
      else
        params[:news][:news_category_id] = new_child.id
      end
    elsif params[:second_level_news_category_id].to_s != '' then
      params[:news][:news_category_id] = params[:second_level_news_category_id]
    end
  end
end
