module HomeHelper
  def comunidad_user_with_photo(user)
    "<div class=\"centered\"><div class=\"photo\"><a href=\"#{gmurl(user)}\"><img src=\"/cache/thumbnails/i/#{Cms::IMGWG2}x#{Cms::IMGWG2}#{user.show_photo}\" /></a></div><a href=\"#{gmurl(user)}\"><span class=\"nick\">#{user.login}</span></a></div>"
  end
end