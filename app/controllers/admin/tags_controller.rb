# -*- encoding : utf-8 -*-
class Admin::TagsController < AdministrationController
  before_filter do |c|
    raise AccessDenied if !Authorization.can_admin_tags?(c.user)
  end

  def index
  end

  def destroy
    uct = UsersContentsTag.find(params[:id])
    if (uct.term.contents_terms.count >
        UsersContentsTag::MAX_TAGS_REFERENCES_BEFORE_DELETE)
      raise "Tried to delete tag with "+
            "#{uct.term.contents_terms.count} references!"
    else
      uct.destroy
    end
    @js_response = "$j('#tag#{uct.id}').fadeOut('normal');"
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end
end

