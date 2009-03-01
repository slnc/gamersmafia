class TutorialesController < InformacionController
  acts_as_content_browser :tutorial
  allowed_portals [:gm, :faction, :bazar, :bazar_district]
  
  def index
    parent_id = params[:category]
    if parent_id then
      @category = Term.find_taxonomy(parent_id, 'TutorialsCategory')
      @category = Term.find_taxonomy(parent_id, nil) if @category.nil?
      raise ActiveRecord::RecordNotFound unless @category
      paths, navpath = get_category_address(@category, 'TutorialsCategory')
      @category.get_ancestors.reverse.each { |p| navpath2<< [p.name, "/tutoriales/#{p.id}"] }
      @title = "Tutoriales de #{@category.name}"
    end
  end
  
  def _after_show
    if @tutorial
      @title = @tutorial.title
      @tutorial.main_category.get_ancestors.reverse.each { |p| navpath2<< [p.name, "/tutoriales/#{p.id}"] }
      navpath2<< [@tutorial.main_category.name, "/tutoriales/#{@tutorial.main_category.id}"]
    end
  end
end
