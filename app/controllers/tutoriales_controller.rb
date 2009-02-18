class TutorialesController < InformacionController
  acts_as_content_browser :tutorial
  allowed_portals [:gm, :faction, :bazar, :bazar_district]
  
  def index
    parent_id = params[:category]
    if parent_id then
      @category = TutorialsCategory.find(parent_id)
      paths, navpath = @category.get_category_address
      @category.get_ancestors.reverse.each { |p| navpath2<< [p.name, "/tutoriales/#{p.id}"] }
      @title = "Tutoriales de #{@category.name}"
    end
  end
  
  def _after_show
    if @tutorial
      @title = @tutorial.title
      @tutorial.tutorials_category.get_ancestors.reverse.each { |p| navpath2<< [p.name, "/tutoriales/#{p.id}"] }
      navpath2<< [@tutorial.tutorials_category.name, "/tutoriales/#{@tutorial.tutorials_category.id}"]
    end
  end
end
