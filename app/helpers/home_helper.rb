# -*- encoding : utf-8 -*-
module HomeHelper
  def comunidad_user_with_photo(user)
    return <<-END
    <div class="centered">
      <div class="photo">
        <a href="#{gmurl(user)}"><img src="/cache/thumbnails/i/#{Cms::IMGWG2}x#{Cms::IMGWG2}#{user.show_photo}" /></a>
      </div>
      <a href="#{gmurl(user)}"><span class="nick">#{user.login}</span></a>
    </div>
    END
  end

  def get_user_daily_joy_term
    case cookies[:sexpref]
    when "dude"
      Term.single_toplevel(:slug => "bazar").children.find(
          :first,
          :conditions => "slug = 'dudes' AND taxonomy = 'ImagesCategory'").id
    when "void"
      nil
    else
      Term.single_toplevel(:slug => "bazar").children.find(
          :first,
          :conditions => "slug = 'babes' AND taxonomy = 'ImagesCategory'").id
    end
  end

  def s_home_contents
    Content.published.find(:all, :order => 'created_on DESC', :limit => 200)
  end
end
