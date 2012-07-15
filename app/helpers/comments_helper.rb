module CommentsHelper
  def adsense_comments
    if App.show_ads && (!user_is_authed || @user.created_on > 1.year.ago)
      ADSENSE_COMMENTS_SNIPPET
    end
  end

  def get_comments(object)
    Comment.paginate({
        :page => params[:page],
        :per_page => Cms.comments_per_page,
        :conditions => ["deleted = 'f' AND content_id = ?",
                        object.unique_content.id],
        :order => 'comments.created_on asc',
        :include => :user
    })
  end

  def resolve_comments_page(object)
    if user_is_authed && !params[:page]
      params[:page] = Cms::page_to_show(@user, object, @object_lastseen_on)
    end

    if params[:page].nil? || params[:page].to_i < 1
      params[:page] = 1
    else
      params[:page] = params[:page].to_i
    end
  end

end
