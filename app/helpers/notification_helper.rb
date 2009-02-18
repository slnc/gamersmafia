module NotificationHelper
  def notification_header(s)
    "<div style=\"background-color: #000; padding-left: 15px; color: #fff; line-height: 33px; font-weight: bold; font-family: tahoma; font-size: 16px;\">#{s}</div>"
  end
  
  def sparklines(o)
    "<img src=\"http://slnc.me/sp/samples/stock_chart.php?d=#{o.join(',')}\" />"
  end
end
