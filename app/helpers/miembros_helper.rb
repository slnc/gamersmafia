module MiembrosHelper  
  def submenu
    'Ficha' if @curuser
  end
  
  def submenu_items
    if @curuser then
      b = gmurl(curuser)
      # blog_add = be_count > 0 ? " (#{be_count})" : ''
      base = [['Información', "#{b}"], ]
      base<< ['Hardware', "#{b}/hardware"]
      base<< ['Amigos', "#{b}/amigos"]
      base<< ['Competición', "#{b}/competicion"]
      base<< ['Estadísticas', "#{b}/estadisticas"]
      
      if @curuser.enable_profile_signatures?
        psigs_add = (@curuser.profile_signatures_count > 0) ? " (#{@curuser.profile_signatures_count})" : ''
        base<< ['Firmas', "#{b}/firmas"] 
      end
      base
    end
  end
  
  def draw_user_info(user)
    out = "<div class=\"members-user-info\">
        <div class=\"avatar\"><img src=\"#{ASSET_URL}#{user.show_avatar}\" /></div>
        <div class=\"userinfonick\">#{link_to user.login, :controller => '/miembros', :action => user.login} #{faction_favicon(user)}</div>
        
        <ul class=\"infoinline\">
          <li>#{draw_karma_bar_sm(user)}</li>
          <li>#{draw_faith_bar_sm(user)}</li>
        </ul>
        <div class=\"clearl\"></div></div>"
  end
  
  def draw_user_info2(user)
    out = "<div class=\"userinfobox2\">

            <div class=\"userinfo\">
                <div class=\"avatar\" style=\"float: left;\"><img src=\"#{ASSET_URL}#{user.show_avatar}\" /></div>
                <div class=\"attributes\">#{render :partial => '/shared/karmabar', :locals => {:user => user}}<br />#{render :partial => '/shared/karmabar', :locals => {:user => user}}<br />#{faction_favicon(user)}</div>
            </div>
            </div>"
  end
  
  def draw_karma_bar_sm(user)
    pcdone = Karma.pc_done_for_next_level(user.karma_points)
    "<div class=\"karma\"><div class=\"points\" style=\"float: left; width: 10px; text-align: right;\">#{Karma.level(user.karma_points)}</div> <div style=\"margin-left: 12px; padding-top: 2px;\"><div class=\"karma\">#{draw_pcent_bar(pcdone.to_f/100, "#{pcdone}%", true)}</div></div></div>"
    #""
  end
  
  def draw_faith_bar_sm(user)
    pcdone = Faith.pc_done_for_next_level(user.faith_points)
    "<div class=\"faith\"><div class=\"points\"><img title=\"Fe: #{Faith::NAMES[Faith.level(user.faith_points)]}\" class=\"sprite1 level#{Faith.level(user.faith_points)}\" style=\"margin: 0;\" src=\"/images/blank.gif\" /></div> <div style=\"margin-left: 12px; padding-top: 2px;\"><div class=\"faith\">#{draw_pcent_bar(pcdone.to_f/100, "#{pcdone}%", true)}</div></div></div>"
  end
  
  def draw_comments_bar_sm(user, refobj)
    # udata = Comments.get_user_comments_type(user, refobj)
    cvt = user.get_comments_valorations_type # CommentsValorationsType.new(:name => 'Normal') # udata[0]
    strength = user.get_comments_valorations_strength # 0.0 # udata[1]
    opacity = user.valorations_weights_on_self_comments / controller.global_vars['max_cache_valorations_weights_on_self_comments'].to_f
    opacity = 1.0 if opacity > 1
    opacity = 0.15 if opacity < 0.15 || opacity.nan?
    # rgb_color = '#' + [1 - opacity, 1 - opacity, 1 - opacity].collect { |v| sprintf("%02x", (v*255).to_i) }.join
    # rgb_color = '#c0c0c0' if rgb_color > '#c0c0c0'
    
    "<style type=\"text/css\">#comment#{refobj.id} .comments-bar .points, #comment#{refobj.id} .comments-bar .pcent-bar .bar { filter: alpha(opacity=#{(opacity*100).to_i}); -khtml-opacity: #{opacity.to_s[0..3]}; -moz-opacity: #{opacity.to_s[0..3]}; opacity: #{opacity.to_s[0..3]}; }</style> <div class=\"comments-bar\"><div class=\"points\" style=\"float: left; width: 10px; margin-top: 2px; text-align: right;\">#{comments_icon(cvt.name.to_sym)}</div> <div style=\"margin-left: 12px; padding-top: 2px;\"><div class=\"comments-bar\">#{draw_pcent_bar(strength, nil, true)}</div></div></div>"
  end
  
  def wii_code(wii_code)
    if wii_code.length == 16
      "#{wii_code[0..3]} #{wii_code[4..7]} #{wii_code[8..11]} #{wii_code[12..15]}"
    else
      wii_code
    end
  end
end
