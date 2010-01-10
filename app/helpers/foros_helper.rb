module ForosHelper
  def draw_topic_indicators(topic)
    icons = []
    if topic.closed then
      icons<< '<img class="sprite1 topic-indicator topic-locked" src="/images/blank.gif" />'
    end

    if topic.moved_on and topic.moved_on > Time.now - 86400 * 7 then
      icons<< '<img class="sprite1 topic-indicator topic-moved" src="/images/blank.gif" />'
    end

    # if topic.hot? then
    #   icons<<  '<img class="sprite1 topic-indicator topic-flame" src="/images/blank.gif" />'
    # end
    # TOO db intensive

    if topic.sticky? then
      icons<< '<img class="sprite1 topic-indicator topic-sticky" src="/images/blank.gif" />'
    end

    icons.join(' ')
  end
end
