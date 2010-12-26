module Cuenta::MensajesHelper  
  def print_thread_tree(msg, curmsg, indent_level=0)
    out = (indent_level == 0) ? '<ul class="messages-thread">' : ""
    # '&nbsp; '*indent_level
    if msg.id == curmsg.id then
      out << "<li><table class=\"compact\"><tr><td class=\"preview\"><strong>#{msg.preview[0..500]}</strong></td><td class=\"w125\">&nbsp; <span class=\"infoinline\">#{print_tstamp(msg.created_on, 'intelligent')}</span> <span class=\"infoinline\"><a href=\"#{gmurl(msg.sender)}\">#{msg.sender.login}</a></span></td></tr></table>"
    else
      out << "<li><table class=\"compact\"><tr><td class=\"preview\"><a href=\"/cuenta/mensajes/mensaje/#{msg.id}/\">#{msg.preview[0..500]}</a></td><td class=\"w125\">&nbsp; <span class=\"infoinline\">#{print_tstamp(msg.created_on, 'intelligent')}</span> <span class=\"infoinline\"><a href=\"#{gmurl(msg.sender)}\">#{msg.sender.login}</a></span></td></tr></table>"  
    end
    
    Message.find(:all, :conditions => ['in_reply_to = ?', msg.id], :order => 'created_on').each do |m|
      # TODO diferenciar quién lo envía
      out << "<ul>" << print_thread_tree(m, curmsg, indent_level + 1) << "</ul>"
    end
    out << "</li>"
    out << "</ul>" if indent_level == 0
    out
  end
  
  def message_quotize(txt)
    prev_is_quoted = false
    txt.split("\n").collect do |ln|
      if ln[0..0] == '>' && !prev_is_quoted
        prev_is_quoted = true
        '[quote]'<<ln
      elsif ln[0..0] != '>' && prev_is_quoted
        prev_is_quoted = false
        ln<<'[/quote]'
      else
      ln
      end
    end.join("\n")
  end
end