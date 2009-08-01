class Admin::TagsController < AdministrationController
  before_filter do |c|
    raise AccessDenied unless c.user && (c.user.has_admin_permission?(:capo) || c.user.is_hq?)
  end

  def index
	
  end

  def destroy
    uct = UsersContentsTag.find(params[:id])
    raise "Tried to delete tag with #{uct.term.contents_terms.count} references!" if uct.term.contents_terms.count > 25
    uct.destroy
    render :nothing => true
  end
end
