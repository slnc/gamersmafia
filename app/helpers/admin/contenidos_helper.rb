# -*- encoding : utf-8 -*-
module Admin::ContenidosHelper
  def draw_content_mod_state(obj)
    points = PublishingDecision.find_sum_for_content(obj)
    h = (points > 0) ? 7 : 14
    a = (points > 0) ? 'left' : 'right'
    points = -1 if points < -1
    points = 1 if points > 1
    w = 51 + (points.abs * 50).to_i
    "<div class=\"modbar\" style=\"text-align: #{a};\"><img style=\"background-position: #{a} -#{h}px; width: #{w}px;\" src=\"/images/blank.gif\" title=\"#{(points.abs * 100).to_i}%\" /></div>"
  end
end
