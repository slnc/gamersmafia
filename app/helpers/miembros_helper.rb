# -*- encoding : utf-8 -*-
module MiembrosHelper
  AVATAR_SIZES = {
    :very_small => 16,
    :small => 32,
    :normal => 50,
  }

  def user_emblem_stats(user)
    split_emblems_mask = user.emblems_mask_or_calculate.split(".")
    out = []
    UsersEmblem::SORTED_DECREASE_FREQUENCIES .each do |frequency|
      emblems_count = split_emblems_mask[User::USER_EMBLEMS_MASKS[frequency]]
      next if emblems_count == '0'
      out << [frequency, emblems_count]
    end
    out
  end

  def sorted_user_emblems_all
    emblems = {}
    UsersEmblem::FREQ_NAME.keys.each do |frequency|
      emblems[frequency] = []
    end

    UsersEmblem::EMBLEMS_INFO.each do |emblem, info|
      emblems[info[:frequency]] << {:emblem => emblem}.merge(info)
    end

    sort_emblems_by_frequency(emblems)
  end

  def sorted_user_emblems(user)
    emblems = {}
    UsersEmblem::FREQ_NAME.keys.each do |frequency|
      emblems[frequency] = []
    end

    user.users_emblems.each do |emblem|
      info = UsersEmblem::EMBLEMS_INFO[emblem.emblem]
      emblems[info[:frequency]] << emblem
    end

    sort_emblems_by_frequency(emblems)
  end

  # Sorts a hash of emblems keyed by their rarity. Each value is a hash with
  # EMBLEMS_INFO-like values.
  def sort_emblems_by_frequency(emblems)
    out =  []
    UsersEmblem::SORTED_DECREASE_FREQUENCIES.each do |frequency|
      emblems[frequency].sort_by {|el| el[:name]}.each do |emblem|
        out << emblem
      end
    end
    out
  end

  def draw_user_info(user)
    out = "<div class=\"members-user-info\">
        <div class=\"avatar\"><img src=\"#{ASSET_URL}#{user.show_avatar}\" /></div>
        <div class=\"userinfonick\">#{link_to user.login, :controller => '/miembros', :action => user.login} #{faction_favicon(user)}</div>

        <ul class=\"infoinline\">
          <li>#{draw_karma_bar_sm(user)}</li>
        </ul>
        <div class=\"clearl\"></div></div>"
  end

  def avatar_img(user, size)
    raise "Invalid size #{size}" unless AVATAR_SIZES.has_key?(size)
    size_px = AVATAR_SIZES[size]
    out = <<-END
    <img title="#{user.login}"
         src="#{ASSET_URL}/cache/thumbnails/f/#{size_px}x#{size_px}#{user.show_avatar}" />
    END
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

  def show_member_control_box
    user_is_authed && (
        @user.has_skill?("Webmaster") ||
        @user.has_skill?("Capo") ||
        Authorization::Users.can_report_users?(@user) ||
        @user.has_skill?("Antiflood")
    )
  end

  # Returns a list of all available karma skills and percentage of completion
  # for a given user.
  def karma_skills_percentages(user)
    out = []
    UsersSkill::KARMA_SKILLS.each do |name, karma|
      if user.has_skill?(name)
        pcent = 1.0
      elsif user.karma_points >= karma
        pcent = 0.99
      else
        pcent = user.karma_points.to_f / karma
      end
      # We always return karma to make sure we always sort the table the same
      # way regardless of the user.
      out << [karma, name, pcent]
    end
    out.sort.reverse.collect {|skill_info| [gm_translate(skill_info[1]),
                                            skill_info[2]]}
  end

  def special_skills(user)
    out = []
    user.users_skills.special_skills.find(:all).each do |skill|
      out << skill.format_scope
    end
    out.sort
  end
end
