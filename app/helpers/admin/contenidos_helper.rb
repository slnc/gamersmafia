module Admin::ContenidosHelper
  def submenu
    'Contenidos'
  end
  
  def submenu_items
    if @user.is_bigboss? then
      return [['Hotmap', '/admin/contenidos/hotmap'], ['Pendientes', '/admin/contenidos'], ['Huérfanos', '/admin/contenidos/huerfanos'], ['Últimas decisiones', '/admin/contenidos/ultimas_decisiones'], ['Papelera', '/admin/contenidos/papelera'], ]
    elsif @user.is_editor? then
      return [['Pendientes', '/admin/contenidos'], ['Huérfanos', '/admin/contenidos/huerfanos'], ['Papelera', '/admin/contenidos/papelera'], ]
    else
      return [['Pendientes', '/admin/contenidos'], ]
    end
  end
  
  def draw_content_mod_state(obj)
    points = PublishingDecision.find_sum_for_content(obj)
    h = (points > 0) ? 7 : 14
    a = (points > 0) ? 'left' : 'right'
    w = 51 + (points.abs * 50).to_i
    "<div class=\"modbar\" style=\"text-align: #{a};\"><img style=\"background-position: #{a} -#{h}px; width: #{w}px;\" src=\"/images/blank.gif\" title=\"#{(points.abs * 100).to_i}%\" /></div>"
  end
end
