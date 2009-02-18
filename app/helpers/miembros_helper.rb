module MiembrosHelper
  def draw_user_info(user)
    out = "
        <div class=\"avatar\" style=\"float: left; margin-right: 3px;\"><img src=\"#{ASSET_URL}#{user.show_avatar}\" /></div>
        <div style=\"font-size: 11px;\" class=\"userinfonick\">#{link_to user.login, :controller => '/miembros', :action => user.login} #{faction_favicon(user)}</div>
        
        <ul style=\"margin: 5px 0 0 0; padding: 0; text-align: left; list-style: none;\" class=\"infoinline\">
          <li style=\"width: 69px; line-height: 10px; margin-bottom: 2px;\">#{draw_karma_bar_sm(user)}</li>
          <li style=\"width: 69px; line-height: 10px;\">#{draw_faith_bar_sm(user)}</li>
        </ul>
        <div style=\"clear: left;\"></div>"
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
    "<div class=\"faith\"><div class=\"points\"><img title=\"Fe: #{Faith::NAMES[Faith.level(user.faith_points)]}\" class=\"level#{Faith.level(user.faith_points)}\" style=\"margin: 0;\" src=\"/images/blank.gif\" /></div> <div style=\"margin-left: 12px; padding-top: 2px;\"><div class=\"faith\">#{draw_pcent_bar(pcdone.to_f/100, "#{pcdone}%", true)}</div></div></div>"
  end

  def draw_comments_bar_sm(user, refobj)
    # udata = Comments.get_user_comments_type(user, refobj)
    cvt = user.get_comments_valorations_type # CommentsValorationsType.new(:name => 'Normal') # udata[0]
    strength = user.get_comments_valorations_strength # 0.0 # udata[1]
    "<div class=\"comments-bar\"><div class=\"points\" style=\"float: left; width: 10px; margin-top: 2px; text-align: right;\">#{comments_icon(cvt.name.to_sym)}</div> <div style=\"margin-left: 12px; padding-top: 2px;\"><div class=\"comments-bar\">#{draw_pcent_bar(strength, nil, true)}</div></div></div>"
  end

  def wii_code(wii_code)
    if wii_code.length == 16
      "#{wii_code[0..3]} #{wii_code[4..7]} #{wii_code[8..11]} #{wii_code[12..15]}"
    else
      wii_code
    end
  end
end
