module NotificationHelper
  def notification_header(s)
    "<div class=\"notification-header\">#{s}</div>"
  end
  
  def sparklines(o)
    "<img src=\"http://slnc.me/sp/samples/stock_chart.php?d=#{o.join(',')}\" />"
  end
end
