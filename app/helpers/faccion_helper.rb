module FaccionHelper
    def draw_faction_portrait(user, faction)
    if faction.is_boss?(user) then
      icons_html = '<img class="faction-role boss" src="/images/blank.gif" />'
    elsif faction.is_underboss?(user) then
      icons_html = '<img class="faction-role underboss" src="/images/blank.gif" />'
    else
      icons_html = ''
      
      # TODO PERF
      faction.editors.each do |u|
        if u.id == user.id then
          icons_html = '<img class="faction-role editor" src="/images/blank.gif" />'
          break
        end
      end

      faction.moderators.each do |u|
        if u.id == user.id then
          icons_html = "#{icons_html}<img class=\"faction-role moderator\" src=\"/images/blank.gif\" />"
          break
        end
      end
    end

    "<div style=\"float: left; text-align: center; margin-right: 6px;\"><a href=\"#{gmurl(user)}\">#{user.login}</a><br /><img style=\"margin: 2px;\" src=\"#{ASSET_URL}#{user.show_avatar}\" /><br />#{icons_html}</div>"
  end
end
