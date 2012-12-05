# -*- encoding : utf-8 -*-
module HomeHelper
  def home_mode
    @home_mode
  end

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

  def stream_main_contents
    content_types = %w(
      BlogEntry
      Column
      Coverage
      Interview
      News
      Question
      Review
      Topic
      Tutorial
    )
    Content.content_type_names(
        content_types).recent.published.of_interest_to(@user).find(
            :all,
            :order => 'created_on DESC',
            :limit => 100,
            :include => :content_type)
  end
end
