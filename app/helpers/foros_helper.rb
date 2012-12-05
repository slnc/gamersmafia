# -*- encoding : utf-8 -*-
module ForosHelper
  def draw_topic_indicators(topic)
    icons = []
    icons << gm_icon("lock", "small") if topic.closed
    icons << gm_icon("sticky", "small") if topic.sticky?
    icons.join(" ")
  end

  def subforums(forum)
    forum.children.paginate(
      :conditions => ["taxonomy = ?", "TopicsCategory"],
      :order => "LOWER(name)",
      :page => params[:page],
      :per_page => 100)
  end

  def get_topics(forum)
    Topic.published.in_term(forum).paginate(
      :order => "sticky DESC, updated_on DESC",
      :page => params[:page],
      :per_page => 50)
  end
end
