# -*- encoding : utf-8 -*-
class KarmaObserver < ActiveRecord::Observer
  observe Content, Comment

  def after_create(object)
    self.after_save(object)
  end

  def after_save(object)
    class_name = object.class.name
    if object.class.superclass.name == "Content"
      class_name = "Content"
    end

    case class_name
    when 'Comment'
      if object.karma_eligible? && object.karma_points.nil?
        Karma.add_karma_after_comment_is_created(object)
      elsif !object.karma_eligible? && object.karma_points
        Karma.del_karma_after_comment_is_deleted(object)
      end

    when 'Content'
      if (object.state == Cms::PUBLISHED && object.source_changed? &&
          object.karma_points)
        Karma.del_karma_after_content_is_unpublished(object)
      end

      if object.state == Cms::PUBLISHED && object.karma_points.nil?
        Karma.add_karma_after_content_is_published(object)
      elsif object.state != Cms::PUBLISHED && object.karma_points
        Karma.del_karma_after_content_is_unpublished(object)
      end

    else
      raise "Don't know how to handle #{object.class.name}"
    end
  end

  def after_destroy(object)
    return if object.karma_points.nil?

    case object.class.name
    when 'Comment'
      Karma.del_karma_after_comment_is_deleted(object)

    when 'Content'
      Karma.del_karma_after_content_is_unpublished(object)

    else
      raise "Don't know how to handle #{object.class.name}"
    end
  end
end
