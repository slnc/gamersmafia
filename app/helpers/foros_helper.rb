# -*- encoding : utf-8 -*-
module ForosHelper
  def draw_topic_indicators(topic)
    icons = []
    if topic.closed then
      icons<< '<img class="sprite1 topic-indicator topic-locked" src="/images/blank.gif" />'
    end

    if topic.moved_on and topic.moved_on > Time.now - 86400 * 7 then
      icons<< '<img class="sprite1 topic-indicator topic-moved" src="/images/blank.gif" />'
    end

    if topic.sticky? then
      icons<< '<img class="sprite1 topic-indicator topic-sticky" src="/images/blank.gif" />'
    end

    icons.join(' ')
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
