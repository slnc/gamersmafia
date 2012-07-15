# -*- encoding : utf-8 -*-
class BlogsController < ComunidadController
  allowed_portals [:gm]

  def index

  end

  def blog
    @curuser = User.find_by_login(params[:login])
    raise ActiveRecord::RecordNotFound unless @curuser && @curuser.blogentries.count > 0 # TODO PERF counter cache
    @title = "Blog de #{@curuser.login}"
    @navpath = [['Blogs', '/blogs'], [@curuser.login, "/blogs/#{@curuser.login}"]]
  end

  def blogentry
    @curuser = User.find_by_login(params[:login])
    raise ActiveRecord::RecordNotFound unless @curuser
    @blogentry = @curuser.blogentries.find(:first, :conditions => ['id = ? AND state = ?', params[:id].to_i, Cms::PUBLISHED])
    raise ActiveRecord::RecordNotFound unless @blogentry
    raise ActiveRecord::RecordNotFound if @curuser.id != @blogentry.user_id

    @title = @blogentry.title
    @navpath = [['Blogs', '/blogs'], [@curuser.login, "/blogs/#{@curuser.login}"], [@blogentry.title, "/blogs/#{@curuser.login}/#{@blogentry.id}"]]

    track_item(@blogentry)
  end

  def ranking
    @title = "Ranking de autoridad"
  end

  def close
    obj = Blogentry.find(params[:id])
    require_user_can_edit(obj)

    obj.update_attributes(:closed => true) unless obj.closed

    flash[:notice] = "#{Cms::CLASS_NAMES['Blogentry']} cerrado a comentarios."
    redirect_to gmurl(obj)
  end
end
