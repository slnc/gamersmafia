module EmblemasHelper
  def emblem_inline_html(emblem)
    emblem_inline_html_from_info(UsersEmblem::EMBLEMS_INFO.fetch(emblem.emblem))
  end

  def emblem_inline_html_from_info(info)
    "<div class=\"emblem #{info[:frequency]}\">
       <div class=\"name\" title=\"#{info[:description]}\">#{gm_icon("emblem-#{info[:frequency]}", "small")} #{info[:name]}</div>
    </div>"
  end
end
