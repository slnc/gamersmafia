# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  COMMENTS_DESPL = {:Normal => '0',
    :Divertido => '12',
    :Informativo => '24',
    :Profundo => '36',
    :Flame => '48',
    :Redundante => '60',
    :Irrelevante => '72',
    :Interesante => '96',
    :Spam => '108',
  }
  
  def draw_emblem(emblema)
    "<img class=\"emblema emblema-#{emblema}\" src=\"/images/blank.gif\" />"  
  end
  
  def sparkline(opts)
    # req: data size
    opts = {:colors => ['0077cc'], :fillcolors => ['E6F2FA']}.merge(opts)
    out = ''
    require 'md5'
    spid = MD5.hexdigest((Time.now.to_i + Kernel.rand).to_s)
    # load_javascript_lib('web.shared/jgcharts-0.9')
    out << "<div id=\"line#{spid}\"></div>
<script type=\"text/javascript\">
$j(document).ready(function() {
var api = new jGCharts.Api(); 
jQuery('<img>') 
.attr('src', api.make({ 
data: [#{opts[:data].join(',')}],
fillarea: true,
fillbottom: true,
size: '#{opts[:size]}',"
    
    out << " max: #{opts[:max]}," if opts[:max]
    out << "linestyle: '1,0,0',
colors: ['#{opts[:colors][0]}'],
fillcolors: ['#{opts[:fillcolors][0]}'],
min: 0, 
type: 'ls'})) 
.appendTo(\"#line#{spid}\");
});
</script>
"
    
    out
  end
  
  def pie(opts)
    # req: data size
    out = ''
    require 'md5'
    spid = MD5.hexdigest((Time.now.to_i + Kernel.rand).to_s)
    # load_javascript_lib('web.shared/jgcharts-0.9')
    out << "<div id=\"line#{spid}\"></div>
<script type=\"text/javascript\">
$j(document).ready(function() {
var api = new jGCharts.Api(); 
jQuery('<img>') 
.attr('src', api.make({ 
data: [#{opts[:data].join(',')}],
size: '#{opts[:size]}',"
    if opts[:axis_labels]
      opts[:axis_labels].collect! { |opt| "'#{opt}'" }
      out << " axis_labels: [#{opts[:axis_labels].join(',')}],"
    end
    out << "
type: 'p'})) 
.appendTo(\"#line#{spid}\");
});
</script>
"
    
    out
  end
  
  def horizontal_stacked_bar(opts)
    # req: data size
    out = ''
    require 'md5'
    spid = MD5.hexdigest((Time.now.to_i + Kernel.rand).to_s)
    # load_javascript_lib('web.shared/jgcharts-0.9')
    out << "<div id=\"line#{spid}\"></div>
<script type=\"text/javascript\">
$j(document).ready(function() {
var api = new jGCharts.Api(); 
jQuery('<img>') 
.attr('src', api.make({ 
data: [#{opts[:data].join(',')}],
size: '#{opts[:size]}',"
    if opts[:axis_labels]
      opts[:axis_labels].collect! { |opt| "'#{opt}'" }
      out << " axis_labels: [#{opts[:axis_labels].join(',')}],"
    end
    out << "
type: 'bhs'})) 
.appendTo(\"#line#{spid}\");
});
</script>
"
    
    out
  end
  
  def header(title, opts={})
    # {:mode => opts
  end
  
  def header_content(title, icon)
    
  end
  
  def header_support(title, icon='')
    
  end
  
  def content_2colx(&block)
    concat("<div class=\"container c2colx\">", block.binding)
    yield
    concat("</div>", block.binding)
  end
  
  def content_3col(&block)
    concat("<div class=\"container c3col\">", block.binding)
    yield
    concat("</div>", block.binding)
  end
  
  def content_3colx(&block)
    concat("<div class=\"container c3colx\">", block.binding)
    yield
    concat("</div>", block.binding)
  end
  
  def content_3coly(&block)
    concat("<div class=\"container c3coly\">", block.binding)
    yield
    concat("</div>", block.binding)
  end
  
  def gmurl(object, opts={})
    ApplicationController.gmurl(object, opts)
  end
  
  def member_state(state)
    "<img class=\"member-state #{state}\" src=\"/images/blank.gif\" />"
  end
  
  def user_link(user, opts={})
    opts = {:avatar => false}.merge(opts)
    out = ''
    if opts[:avatar] then
      # avatar y link en negrita
      out << "<img style=\"float: left; margin-right: 5px;\" class=\"avatar\" src=\"#{user.show_avatar}\" /> <strong><a href=\"#{gmurl(user)}\">#{user.login}</a></strong>"
    else
      out << "<a href=\"#{gmurl(user)}\">#{user.login}</a>"
    end
    out
  end
  
  def comments_icon(name, desp=false)   
    vdesp = desp ? '0' : '12'
    '<img class="comments-icon" src="/images/blank.gif" style="background-position: -' << COMMENTS_DESPL[name] << 'px -' << vdesp << 'px;" />'
  end
  
  def get_url(obj)
    case obj.class.name
      when 'User':
      gmurl(obj)
      when 'Clan':
      "/clanes/clan/#{obj.id}"
      when 'Faction'
      gmurl(obj)
      when 'Tournament'
      "/competiciones/show/#{obj.id}"
      when 'Ladder'
      "/competiciones/show/#{obj.id}"
      when 'League'
      "/competiciones/show/#{obj.id}"
    else
      controller.url_for_content_onlyurl(obj)
    end
  end
  
  NLS_SERVERS = Dir.entries("#{RAILS_ROOT}/public/images/ads/nls").collect { |e| e.gsub('.jpg', '') if  /.jpg/ =~ e }.compact
  
  NLS_SERVERS<< 'nls-cod41'
  NLS_SERVERS<< 'nls-cod42'
  NLS_SERVERS<< 'nls-cod41'
  NLS_SERVERS<< 'nls-cod42'
  NLS_2X = %w(nls-cod41 nls-cod42)
  #%w(nls-side nls-de12a28 nls-linea3gbpspropia nls-quadcore16 nls-ts2ftpwebgratis nls-wwwnlses)
  
  def googleads(options={})
    options = {:adsense => true, :colors => controller.portal.skin.config[:google_ads]}.merge(options)
    # No habilitar lo siguiente, lo hice para no mostrar googleads en pags a las que google no puede llegar pero lógicamente esa línea es una chapuza
    #    options[:adsense] = false if controller.user_is_authed
    # TODO añadir una protección mejor para no mostrarlo en páginas de cuenta
    # We increase the odds of a cod4 banner appearing
    nlsad = NLS_SERVERS[rand(NLS_SERVERS.size)]
    
    out = "<div style=\"text-align: center; margin-bottom: 20px\">
        <a class=\"slncadt\" id=\"#{nlsad}\" target=\"_blank\" title=\"Servidores de juegos desde 40€/mes\" href=\"http://www.nls.es/\"><img style=\"border: 0;\" src=\"/images/ads/nls/#{nlsad}.jpg\" /></a>"
    Stats.account_ad_impression(request, nlsad, user_is_authed ? @user.id : nil, @portal.id)
    if (!%w(admin Contenidos).include?(controller.submenu)) && !(controller.controller_name == 'imagenes') && options[:adsense] then
      out<< '<div style="margin-top: 20px;">     <script type="text/javascript"><!--
      google_ad_client = "pub-6007823011396728";
      google_alternate_color = "FFFFFF";
      google_ad_width = 234;
      google_ad_height = 60;
      google_ad_format = "234x60_as";
      google_ad_type = "text";
      google_ad_channel ="0672237315";
google_color_border = "' + options[:colors][:google_color_border]+'";
google_color_bg = "' + options[:colors][:google_color_bg]+'";
google_alternate_color = "' + options[:colors][:google_alternate_color]+'";
google_color_link = "' + options[:colors][:google_color_link]+'";
google_color_url = "' + options[:colors][:google_color_url]+'";
google_color_text = "' + options[:colors][:google_color_text]+'";
      //--></script>
      <script type="text/javascript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js"> </script>'
      Stats.account_ad_impression(request, 'google_234x60', user_is_authed ? @user.id : nil, @portal.id)
      if 1 == 0 && !user_is_authed then
        out<<'
	      <script type="text/javascript"><!--
	      google_ad_client = "pub-6007823011396728";
	      google_alternate_color = "FFFFFF";
	      google_ad_width = 234;
	      google_ad_height = 60;
	      google_ad_format = "234x60_as";
	      google_ad_type = "text";
	      google_ad_channel ="4498901023";
		  google_color_border = "ffffff";
		  google_color_bg = "fafafa";
		  google_color_link = "AD0011";
		  google_color_text = "a0a0a0";
		  google_color_url = "008000";
	      //--></script>
	     <script type="text/javascript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js"> </script> '
      end
      out<<'
        </div>
      '
      
    end
    
    if controller.params[:nls2x] then
      nlsad = NLS_SERVERS[rand(NLS_SERVERS.size)]
      
      out << "
        <br /><a class=\"slncadt\" id=\"#{nlsad}\" target=\"_blank\" title=\"Servidores de juegos desde 40€/mes\" href=\"http://www.nls.es/\"><img style=\"border: 0;\" src=\"/images/ads/nls/#{nlsad}.jpg\" /></a>"
    end
    
    out<< '</div>'
    out
  end
  
  def notags(txt)
    txt.to_s.gsub('<', '&lt;').gsub('>', '&gt;')
  end
  
  def faction_favicon(thing)
    Cms.faction_favicon(thing)
  end
  
  def content_category(thing)
    "<div class=\"content-category\">#{faction_favicon(thing)}</div>"
  end
  
  def render_tree_list(objs, options = {})
    return '' if objs.nil? or objs.size == 0    
    out = options[:ul_class] ? "<ul class=\"#{options[:ul_class]}\"" : '<ul'
    options[:level] ||= 0 
    out<< " style=\"margin-left: #{15*options[:level]}px\">"
    options[:level] += 1
    objs = [objs] unless objs.respond_to?(:to_a)
    objs.each do |obj|
      out << (options[:li_class] ? "<li class=\"#{options[:li_class]}\">" : '<li>')
      out << "<a href=\"#cat#{obj.id}\">#{obj.name}</a>" << render_tree_list(obj.children, options) << "</li>\n"
    end
    out << '</ul>'
  end
  
  # TODO cachear
  def render_tree_select(pages, name, select_name, value = nil, noparent_id=false)
    ret = ''
    
    found = false
    for page in pages 
      if page.parent_id == nil || noparent_id
        if page.id == value then
          ret += "<option selected=\"selected\" value=\"#{page.id}\">"
          found = true
        else
          ret += "<option value=\"#{page.id}\">" 
        end
        ret += page[name] if page[name] 
        ret += recurse_tree(page, 0, name, value) if page.children and page.children.size>0 
      end
    end 
    ret += "</select>"
    
    if (!found) && noparent_id
      ret = "<select id=\"#{select_name}\" name=\"#{select_name}\"><option value=\"#{value unless value.nil?}\"></option>#{ret}"
    else
      ret = "<select id=\"#{select_name}\" name=\"#{select_name}\"><option value=\"\"></option>#{ret}"
    end
    
    ret
  end
  
  def recurse_tree(page, depth, name, value)
    depth = depth + 1
    level = "- " * depth
    ret = ''
    if page.children.size > 0
      page.children.each { |subpage| 
        if subpage.children.size > 0
          if subpage.id == value then
            ret += '<option selected="selected" value="'+subpage.id.to_s+'">'
          else
            ret += '<option value="'+subpage.id.to_s+'">'
          end
          ret += h(level + subpage[name])
          ret += recurse_tree(subpage, depth, name, value)
          ret += '</option>'
        else
          if subpage.id == value then
            ret += '<option selected="selected" value="'+subpage.id.to_s+'">'
          else
            ret += '<option value="'+subpage.id.to_s+'">'
          end
          ret += h(level + subpage[name])
          ret += '</option>'
        end
      }
      ret += ''
    end
  end
  
  
  def hide_email(str)
    if Cms::EMAIL_REGEXP =~ str
      parts = str.split('@')
      "<script type=\"text/javascript\">document.write('#{parts[0]}')</script>&#64;<script type=\"text/javascript\">document.write('#{parts[1]}')</script>"
    else
      str 
    end
  end
  
  def smilelize(text)
    return text if text.nil?
    text = "#{text}"
    
    text.gsub!('<br />', "SALTOLINEA333\n") if text.index('<p>').to_s == '' # TODO deprecated
    
    text.gsub!(/\r\n/, "\n")
    text.gsub!(/\r/, "\n")
    text = Cms.add_p(text) if text.index('<p>').to_s == '' # si tiene <p> suponemos que está bien formateado ya
    text = " #{text}"
    text.gsub!(/([\s>]{1}|^)[oO]{1}:(\))+/, '\1<img src="/images/smileys/angel.gif" />')      # o:)
    
    text.gsub!(/([\s>]{1}|^)(:['_*´]+(\()+)/, '\1<img src="/images/smileys/cry.gif" />')      # // :'( | :*( | :_( | :´(
    text.gsub!(/([\s>]{1}|^):([a-z0-9]+):/, '\1<img src="/images/smileys/\2.gif" />')
    text.gsub!(/([\s>]{1}|^)(:(o)+)/i, '\1<img src="/images/smileys/eek.gif" />')             #// :o | :O
    text.gsub!(/([\s>]{1}|^)(r_r)/i, '\1<img src="/images/smileys/roll.gif" />')
    text.gsub!(/([\s>]{1}|^)(x_x)/i, '\1<img src="/images/smileys/ko.gif" />')
    text.gsub!(/([\s>]{1}|^)(z_z)/i, '\1<img src="/images/smileys/zz.gif" />')
    text.gsub!(/([\s>]{1}|^)(o(_)+(o)+)/i, '\1<img src="/images/smileys/eek.gif" />')         #// o_O
    text.gsub!(/([\s>]{1}|^)(:(p)+)/i, '\1<img src="/images/smileys/tongue.gif" />\\4')          #// :p | :P
    
    text.gsub!(/([\s>]{1}|^)(x(d)+)/i, '\1<img src="/images/smileys/grin.gif" />')            #// xd TODO TODO TODO acabar de poner el comienzo de línea a las demás smileys
    
    text.gsub!(/([\s>]{1}|^)(:(0)+)/, '\1<img src="/images/smileys/eek.gif" />')              #// :0
    text.gsub!(/([\s>]{1}|^)(8\)+)/, '\1<img src="/images/smileys/cool.gif" />')              #// 8)
    text.gsub!(/([\s>]{1}|^)(:\?+)/, '\1<img src="/images/smileys/huh.gif" />')              #// :?
    text.gsub!(/([\s>]{1}|^)(:x+)/i, '\1<img src="/images/smileys/lipsrsealed.gif" />')              #// :x
    text.gsub!(/([\s>]{1}|^)(:(\|)+)/, '\1<img src="/images/smileys/indifferent.gif" />')     #// :|
    text.gsub!(/([\s>]{1}|^)(\^(_)*(\^)+)/, '\1<img src="/images/smileys/happy.gif" />')      #// ^^ | ^_^
    text.gsub!(/([\s>]{1}|^)(;([\)D])+)/, '\1<img src="/images/smileys/wink.gif" />')         #// )
    text.gsub!(/([\s>]{1}|^)(:(\*)+)/, '\1<img src="/images/smileys/morreo.gif" />')            #// :*
    text.gsub!(/([\s>]{1}|^)(:(\@)+)/, '\1<img src="/images/smileys/morreo.gif" />')            #// :@
    text.gsub!(/([\s>]{1}|^)(:(\\)+)/, '\1<img src="/images/smileys/undecided.gif" />')           #// :)
    text.gsub!(/([\s>]{1}|^)(:(\))+)/, '\1<img src="/images/smileys/smile.gif" />')           #// :)
    text.gsub!(/([\s>]{1}|^)(x(\))+)/i, '\1<img src="/images/smileys/happy.gif" />')          # // x)
    text.gsub!(/([\s>]{1}|^)(:(D)+)/i, '\1<img src="/images/smileys/happy.gif" />')           ##// :D
    text.gsub!(/([\s>]{1}|^)(:(\()+)/, '\1<img src="/images/smileys/sad.gif" />')             #// :(
    text.gsub!(/([\s>]{1}|^)=(\))+/, '\1<img src="/images/smileys/smile.gif" />')             #// =)
    
    if text.index('SALTOLINEA333').to_s != '' then
      text.gsub!("SALTOLINEA333\n", '</p><p>')
      text = "#{text}</p>"
      text = text.gsub('<p></p>', '')
      text = text.gsub('<p><p>', '<p>')
      text = text.gsub('</p></p>', '</p>')
    end
    
    text.strip!
    
    # TODO cambiar nombre de función
    # text = text.gsub(/((http|ftp|irc|unreal):\/\/([^\s]+))/, '<a class="external" href="\1">\3</a>')
    return text
  end
  
  def user_is_authed
    self.controller.user_is_authed
  end
  
  def print_forum_path(category)
    asc = category.get_ancestors.reverse
    asc<< category
    out = ''
    
    for c in asc
      out<< " &raquo; <a href=\"/foros/forum/#{c.id}\">#{c.name}</a>"
    end
    
    out
  end
  
  def draw_pcent_bar(pcent, text = nil, compact=false)
    # 0 <= pcent <= 1
    if (pcent.kind_of?(Float) && pcent.nan? ) || pcent == Infinity
      pcent = 0
    elsif pcent > 1.0
      pcent = 1.0
    end
    
    # text = "%.2f" % pcent if text == nil
    text = "#{(pcent*100).to_i}%" if text == nil
    
    "<div class=\"pcent-bar#{(compact)?' compact':''}\"><img src=\"/images/blank.gif\" title=\"#{text}\" class=\"bar\" style=\"width: #{(pcent*100).to_i}%;\" /></div>"
  end
  
  def draw_rating(rating_points)
    if rating_points.nil?
      src = 'grey'
      text = 'No hay suficientes valoraciones'
    else
      src = rating_points
      text = "Valoración: #{src}"
    end
    
    "<span class=\"rating stars#{src}\"><span><img alt=\"#{text}\" title=\"#{text}\" src=\"/images/blank.gif\" width=\"64\" height=\"13\" /></span></span>"
  end
  
  def draw_contentheadline(content)
    "<div class=\"infoinline\">#{print_tstamp(content.created_on)} | #{draw_rating(content.rating[0])} | <span class=\"comments-count\"><a title=\"Ver comentarios\" href=\"#{controller.url_for_content_onlyurl(content)}\#comments\">#{content.unique_content.comments_count}</a></span></div>"
  end
  
  def draw_faction_building(faction_id, stories=1)
    if File.exists?("#{RAILS_ROOT}/public/storage/factions/#{faction_id}/building_top.png") 
      out = "<div style=\"margin: 2px;\"><img src=\"/storage/factions/#{faction_id}/building_top.png\" /><br />"
      stories.times do
        out << "<img src=\"/storage/factions/#{faction_id}/building_middle.png\" /><br />"
      end
      out << "<img src=\"/storage/factions/#{faction_id}/building_bottom.png\" /></div>"
    else
    "<div style=\"margin: 2px;\"></div>"
    end
  end
  
  def gmd10
    '<img class="gmd10" alt="Dólares GM" src="/images/blank.gif" />'
  end
  
  def gmd12
    '<img class="gmd12" alt="Dólares GM" src="/images/blank.gif" />'
  end
  
  def gmd11
    '<img class="gmd11" alt="Dólares GM" src="/images/blank.gif" />'
  end
  
  def clan_switcher
    out = "
<script type=\"text/javascript\">
  function switch_clan_page(new_clan)
{
  if (new_clan == 'new') 
    document.location = '/cuenta/clanes/new';
  else if (new_clan != '')
    document.location = '/cuenta/clanes/switch_active_clan/'+new_clan;
}
</script>
<select onchange=\"switch_clan_page(this.value);\">
  <option value=\"\"></option>
  <option value=\"new\" style=\"margin-bottom: 10px;\">Crear nuevo clan</option>
  <optgroup label=\"Tus clanes\">"
    for clan in @user.clans
      out<< "<option #{(@clan and @clan.id == clan.id) ? 'selected=\"selected\"' : ''} value=\"#{clan.id}\">#{clan.name}</option>"
    end
    
    out<< "</optgroup>
  </select>"
    out
  end
  
  def competition_switcher
    out = "
<script type=\"text/javascript\">
  function switch_competition_page(new_competition)
{
  if (new_competition == 'new') 
    document.location = '/cuenta/competiciones/new';
  else if (new_competition != '')
    document.location = '/cuenta/competiciones/switch_active_competition/'+new_competition;
}
</script>
<select onchange=\"switch_competition_page(this.value);\">
  <option value=\"\"></option>
  <option value=\"new\" style=\"margin-bottom: 10px;\">Crear nueva competición</option>
  <optgroup label=\"Tus competitiones\">"
    for competition in Competition.find_related_with_user(@user.id)
      out<< "<option #{(@competition and @competition.id == competition.id) ? 'selected=\"selected\"' : ''} value=\"#{competition.id}\">#{competition.name}</option>"
    end
    
    out<< "</optgroup>
  </select>"
    out
  end
  
  def popup(link_text, link_url, width, height)
    "<a href=\"#{link_url}\" onclick=\"window.open('#{link_url}', '_blank', 'width=#{width},height=#{height}'); return false;\">#{link_text}</a>"
  end
  
  def wysiwyg(field_name, opts={})
    opts[:value] ||= ''
    opts[:height] ||= '400px'
    switch1 = "<a class=\"infoinline\" href=\"#\" onclick=\"wysiwyg_mode('fckeditor');\">Prueba el nuevo editor BETA (<strong>¡Se perderán los cambios no guardados!</strong>)</a>"
    switch2 = "<a class=\"infoinline\" href=\"#\" onclick=\"wysiwyg_mode('default');\">Volver al editor de siempre (<strong>¡Se perderán los cambios no guardados!</strong>)</a>"
    
    if params[:fckeditor] || cookies['wysiwygpref'] == 'fckeditor' then
      load_javascript_lib('fckeditor')
      opts[:value] = escape_javascript(opts[:value])
      <<-END
      #{switch2}
      <script type="text/javascript">
        var oFCKeditor = new FCKeditor('#{field_name}');
        oFCKeditor.Config["CustomConfigurationsPath"] = "/fckeditor_cfg.js"  ;
        oFCKeditor.BasePath = "/fckeditor/";
        oFCKeditor.Height = '#{opts[:height]}';
        oFCKeditor.Value = '#{opts[:value]}';
        oFCKeditor.Create();
      </script>
END
    else
      load_javascript_lib('wseditor')
      <<-END
        #{switch1}
        <textarea name="#{field_name}">#{opts[:value]}</textarea><br />
        <script language="JavaScript">new wsEditor('#{field_name}', '99%', '#{opts[:height]}', 'wsEditor.css');</script>
    END
    end
  end
  
  def load_javascript_lib(lib)
    @_additional_js_libs ||= []
    @_additional_js_libs << lib
  end
  
  def get_last_commented_contents
    # TODO ugly
    if @controller.portal_code && @controller.portal.class.name == 'FactionsPortal'
      # contents_condition = @controller.portal.contents_condition
      ids = [0] + @controller.portal.games.collect { |g| g.id }
      contents = Content.find(:all, :conditions => "comments_count > 0 and is_public = 't' AND ((game_id is null AND clan_id IS NULL) OR game_id IN (#{ids.join(',')}))", :order => 'updated_on DESC', :limit => 15)
    elsif @controller.portal_code && @controller.portal.class.name == 'ClansPortal'
      # TODO falta una condición para restringir al clan concreto
      contents = Content.find(:all, :conditions => "comments_count > 0 and is_public = 't' AND clan_id = #{@portal_clan.id}", :order => 'updated_on DESC', :limit => 15)
    else
      contents = Content.find(:all, :conditions => "comments_count > 0 and is_public = 't' AND ((game_id is null AND clan_id IS NULL) OR game_id IS NOT NULL)", :order => 'updated_on DESC', :limit => 15)
    end
    real_objects = contents.collect { |c| c.real_content }
  end
  
  
  def content_bottom(obj)
    if user_is_authed and obj.state == Cms::PENDING and obj.class.name != 'Blogentry' and @user.id != obj.user_id
      controller.send(:render_to_string, :partial => '/shared/accept_or_deny', :locals => { :object => obj })
    elsif [Cms::PUBLISHED, Cms::DELETED, Cms::ONHOLD].include?(obj.state)
      out = controller.send(:render_to_string, :partial => 'shared/contentinfobar', :locals => { :object => obj })
      out<< controller.send(:render_to_string, :partial => 'shared/comments', :locals => { :object => obj })
    else
      ''
    end
  end
  
  
  # selected_games is an array of selected games_ids
  def games_selector(fieldname, selected_games=[])
    total_games = Game.count 
    interval = total_games / 3
    i = 0
    col1 = ''
    col2 = ''
    col3 = ''
    
    for g in Game.find(:all, :order => 'lower(name) ASC')
      if i < interval then
        dst = col1
      elsif i < interval * 2 then
        dst = col2
      else
        dst = col3
      end
      
      selected = selected_games.include?(g.id) ? "checked=\"checked\"" : ''
      dst<< "<label><input type=\"checkbox\" name=\"#{fieldname}[]\" #{selected} value=\"#{g.id}\" /> #{g.name} #{faction_favicon(g)}</label><br />"
      i += 1
    end
    
    "<table>
      <tr>
        <td>#{col1}</td>
        <td>#{col2}</td>
        <td>#{col3}</td>
      </tr>
    </table>
    <br />"
  end
  
  def generic_contents_list(collection, opts={})
    opts = {:action => :show}.merge(opts)
    out = '<ul class="content-hid">'
    collection.each { |obj| out<< "<li><a href=\"#{gmurl(obj).gsub('show', opts[:action].to_s)}\">#{obj.resolve_hid}</a></li>" }
    out << '</ul>'
  end
  
  def draft_check_box(obj)
    if (obj.state.nil? || obj.state == Cms::DRAFT) && !(controller.portal.respond_to?(:clan_id) && controller.portal.clan_id)
      "<p><label><input type=\"checkbox\" name=\"draft\" value=\"1\" #{'checked=\"checked\"' if (obj.state == Cms::DRAFT && !obj.new_record?) }/> Borrador</label></p>"
    end
  end
  
  
  def ad(which, options={})
    case which
      when :nls_big_sample
      out = "<a class=\"slncadt\" id=\"nls-big-sample\" title=\"Servidores de juegos\" target=\"_blank\" href=\"http://www.nls.es/\"><img class=\"icon\" src=\"/images/ads/nls-side/sample.jpg\" /></a>"
      
      when :google_clans_120x600  
      out = '<script type="text/javascript"><!--
google_ad_client = "pub-6007823011396728";
google_ad_width = 120;
google_ad_height = 600;
google_ad_format = "120x600_as";
google_ad_type = "text";
//2007-07-22: GM ads clanes 120x600
google_ad_channel = "6412779129";
google_color_border = "CCCCCC";
google_color_bg = "F3F2EC";
google_color_link = "0066CC";
google_color_text = "333333";
google_color_url = "32527A";
google_ui_features = "rc:6";
//-->
</script>
<script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>'
      
      when :google_skyscraper
      out = '<script type="text/javascript"><!--
      google_ad_client = "pub-6007823011396728";
      google_alternate_color = "FFFFFF";
      google_ad_width = 120;
      google_ad_height = 600;
      google_ad_format = "120x600_as";
      google_ad_type = "text_image";
      //2007-09-09: gm skyscraper
      google_ad_channel = "0318559239";
      google_color_border = "ffffff";
      google_color_bg = "F3F2EC";
      google_color_link = "CC0000";
      google_color_text = "333333";
      google_color_url = "800040";
      google_ui_features = "rc:0";
      //-->
      </script>
      <script type="text/javascript"
        src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
        </script>'
      
      when :fourfrags
      ads = [
      ['steelpad_5l_w', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=796&amp;affiliate_banner_id=1'],
      ['custom_pc', 'http://www.4frags.com/catalog/ccc.php?ref=60&amp;affiliate_banner_id=1'],
      ['custom_pc2', 'http://www.4frags.com/catalog/ccc.php?ref=60&amp;affiliate_banner_id=1'],
      ['steelsound4h', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=1390&amp;affiliate_banner_id=1'],
      ['zboard_fang', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=1246&amp;affiliate_banner_id=1'],
      ['logitech_g15_2008', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=2591&amp;affiliate_banner_id=1'],
      ['logitech_g9_laser', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=2448&amp;affiliate_banner_id=1'],
      ['zboard_merc_stealth', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=3281&amp;affiliate_banner_id=1'],
      ['senheiser_hd_515_gaming', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=3660&amp;affiliate_banner_id=1'],
      ['razer_lanchesis_banshee_blue', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=2923&amp;affiliate_banner_id=1'],
      ['ocx_dimm_2x2', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=3040&amp;affiliate_banner_id=1'],
      ['zboard_base', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=1344&amp;affiliate_banner_id=1'],
      ['wow_tbc', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=3987&amp;affiliate_banner_id=1'],
      ['evga_gforce9800gx2', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=3570&amp;affiliate_banner_id=1'],
      ['ocz_stealthxstream_500w', 'http://www.4frags.com/catalog/product_info.php?ref=60&amp;products_id=3393&amp;affiliate_banner_id=1'],
      ]
      r = Kernel.rand(ads.size)
      out = "<a class=\"slncadt\" id=\"fourfrags-#{ads[r][0]}\" title=\"Más información sobre este producto\" target=\"_blank\" href=\"#{ads[r][1]}\"><img class=\"icon\" src=\"/images/ads/4frags/#{ads[r][0]}.jpg\" /></a>"
      element_id = "fourfrags-#{ads[r][0]}"
      
      when :google_728x15
      out = '<script type="text/javascript"><!--
google_ad_client = "pub-6007823011396728";
google_ad_width = 728;
google_ad_height = 15;
google_ad_format = "728x15_0ads_al";
google_ad_channel ="' + options[:ad_channel] + '";
google_alternate_ad_url = "http://gamersmafia.com/site/banners_bottom";
google_color_border = "' + options[:colors][:google_color_border]+'";
google_color_bg = "' + options[:colors][:google_color_bg]+'";
google_alternate_color = "' + options[:colors][:google_alternate_color]+'";
google_color_link = "' + options[:colors][:google_color_link]+'";
google_color_url = "' + options[:colors][:google_color_url]+'";
google_color_text = "' + options[:colors][:google_color_text]+'";
//--></script>
<script type="text/javascript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js"> </script>'
    else
      raise "unknown ad #{which}"
    end
    Stats.account_ad_impression(request, defined?(element_id) ? element_id : which, user_is_authed ? @user.id : nil, @portal.id)
    out
  end
  
  def prototype_includes
  <<-END
  <script src="#{ASSET_URL}/javascripts/prototype/prototype.js?#{SVNVERSION}" type="text/javascript"></script>
  <script src="#{ASSET_URL}/javascripts/prototype/scriptaculous.js?#{SVNVERSION}" type="text/javascript"></script>
  <script src="#{ASSET_URL}/javascripts/prototype/effects.js?#{SVNVERSION}" type="text/javascript"></script>
  <script src="#{ASSET_URL}/javascripts/prototype/dragdrop.js?#{SVNVERSION}" type="text/javascript"></script>
  <script src="#{ASSET_URL}/javascripts/prototype/controls.js?#{SVNVERSION}" type="text/javascript"></script>
END
  end
  
  def javascript_includes
    if App.compress_js?
      out = "<script type=\"text/javascript\" src=\"#{ASSET_URL}/gm.#{SVNVERSION}.js\"></script>\n"
    else
      out = <<-END 
<script src="#{ASSET_URL}/javascripts/web.shared/jquery-1.2.6.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/web.shared/jquery.scrollTo-1.4.0.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/jquery-ui-personalized-1.6rc2.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/web.shared/jgcharts-0.9.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/jrails.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/jquery.facebox.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/web.shared/slnc.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/app.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/tracking.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/wseditor.#{SVNVERSION}.js" type="text/javascript"></script>
<script src="#{ASSET_URL}/javascripts/app.bbeditor.#{SVNVERSION}.js" type="text/javascript"></script>
      END
    end
    
    if @_additional_js_libs
      @_additional_js_libs.uniq.each do |lib|
        if lib == 'fckeditor'
          out << "<script src=\"#{ASSET_URL}/fckeditor/fckeditor.js\" type=\"text/javascript\"></script>"
        elsif lib.include?('http://')
          out << "<script src=\"#{lib}\" type=\"text/javascript\"></script>"
        else      
          out << <<-END
<script src="#{ASSET_URL}/javascripts/#{lib}.#{'pack.' if App.compress_js?}#{SVNVERSION}.js" type="text/javascript"></script>
        END
        end
      end
    end
    out.strip
  end
  
  def css_includes
    "<link href=\"#{ASSET_URL}#{controller.skin.css_include}\" media=\"all\" rel=\"Stylesheet\" type=\"text/css\" />"
  end
  
  def submenu_name
    case controller.submenu
      when 'Facción':
      "Mi Facción"
      when 'Clan':
      "Mis Clanes"
    else
      Inflector::humanize(Inflector::tableize(controller.submenu))
    end
  end
  
  def navpath
    out = '<ul>'
    out<< '<li class="home"><a title="Ir a portada" class="nav" href="/"><span>Portada</span></a></li>' unless controller.controller_name == 'home' 
    if @navpath # TODO oldschool navpath, remove all of 'em
      #return '' if @navpath.size == 1
      last = @navpath.pop # TODO remove pop directamente en todos los controllers y quitar aquí (a la vez)
      @navpath.each { |np_name, np_url| out<< "<li><a class=\"nav\" href=\"#{np_url}\">#{np_name}</a></li>" unless np_name == 'Application'}
      out<< "<li class=\"current\">#{last[0]}</li>" if last
    elsif controller.controller_name != 'home' && controller.navpath2 then
      #return '' if controller.navpath2.size == 1
      controller.navpath2.each { |np_name, np_url| out<< "<li><a class=\"nav\" href=\"#{np_url}\">#{np_name}</a></li>"  unless np_name == 'Application' }
      out<< "<li class=\"current\">#{controller.title}</li>"
      #else
      #return ''
    end
    out<< '</ul>'
  end
  
  def navpathgm20085
    out = '<ul>'
    firstlevelname = controller.active_sawmode ? controller.active_sawmode.titleize : 'Portada'
    out<< "<li class=\"home\"><a title=\"Ir a portada\" class=\"nav\" href=\"/\"><span>#{firstlevelname}</span></a></li>" 
    if @navpath # TODO oldschool navpath, remove all of 'em
      #return '' if @navpath.size == 1
      last = @navpath.pop # TODO remove pop directamente en todos los controllers y quitar aquí (a la vez)
      @navpath.each { |np_name, np_url| out<< "<li><a class=\"nav\" href=\"#{np_url}\">#{np_name}</a></li>" unless np_name == 'Application'}
      out<< "<li class=\"current\">#{last[0]}</li>" if last
    elsif controller.controller_name != 'home' && controller.navpath2 then
      #return '' if controller.navpath2.size == 1
      controller.navpath2.each { |np_name, np_url| out<< "<li><a class=\"nav\" href=\"#{np_url}\">#{np_name}</a></li>"  unless np_name == 'Application' }
      out<< "<li class=\"current\">#{controller.title}</li>"
      #else
      #return ''
    end
    out<< '</ul>'
  end
  
  def show_url(url)
    nurl = url.gsub('http://', '')
    nurl.gsub('/', '') if nurl.count('/') == 1
    nurl
  end
  
  def show_rating_title(obj)
    if obj.is_public?
      out = "<div id=\"content-stats-title\">"
      out<< "<div id=\"content-stats2\" class=\"content-rating\" class=\"centered\">#{draw_rating(obj.rating[0])}</div>"
      out<< '</div>'
    end
  end
  
  def show_rating(obj)
    if obj.is_public?
      out = "<div id=\"content-stats\">"
      out<< "<div class=\"content-rating\" class=\"centered\">#{draw_rating(obj.rating[0])}<br /><span class=\"infoinline\">(#{obj.rating[1]} valoraciones)</span></div>"
      if obj.respond_to?(:downloaded_times) then
        out<< "<div class=\"pageviews-count\" style=\"line-height: 18px;\" title=\"Leído #{obj.hits_anonymous + obj.hits_registered} veces\"><strong>#{obj.hits_anonymous + obj.hits_registered}</strong> lecturas</div><div class=\"downloads-count\" style=\"line-height: 18px;\" title=\"Descargado #{obj.downloaded_times} veces\"><strong>#{obj.downloaded_times}</strong> descargas</div>"
      else
        out<< "<div class=\"pageviews-count\" style=\"line-height: 18px;\" title=\"Leído #{obj.hits_anonymous + obj.hits_registered} veces\"><strong>#{obj.hits_anonymous + obj.hits_registered}</strong> lecturas</div>"
      end
      out<< '</div>'
    end
  end
  
  def show_news_category_file(file)
    "<img class=\"news-category-image\" src=\"#{ASSET_URL}/cache/thumbnails/f/188x110/#{file}\" />"
  end
  
  def content_support(opts={}, &block)
    opts = {:show_ads => true}.merge(opts)
    return '' if controller.portal.kind_of?(ClansPortal)
    out = ''
    #ab_test('sideright NLS-bandits', 0, :add_xab_to_links => true, :returnmode => :out) { out = ads_slots('sideright-random', '2-0') }
    #ab_test('sideright NLS-bandits', 1, :add_xab_to_links => true, :returnmode => :out) { out = ads_slots('sideright-epsilongreedy', '2-1') }
    #ab_test('sideright NLS-bandits', 2, :add_xab_to_links => true, :returnmode => :out) { out = ads_slots('sideright-epsilonfirst', '2-2') }
    #ab_test('sideright NLS-bandits', 3, :add_xab_to_links => true, :returnmode => :out) { out = ads_slots('sideright-epsilondecreasing', '2-3') }
    #ab_test('sideright NLS-bandits', 4, :add_xab_to_links => true, :returnmode => :out) { out = ads_slots('sideright-softmax', '2-4') }
    #ab_test('sideright NLS-bandits', 5, :add_xab_to_links => true, :returnmode => :out) { out = ads_slots('sideright-leasttaken', '2-5') }
    #ab_test('sideright NLS-bandits', 6, :add_xab_to_links => true, :returnmode => :out) { out = ads_slots('sideright-poker', '2-6') }
    
    concat("<div class=\"container\" id=\"csupport\"><div class=\"ads-slots\"><div class=\"ads-slots1\">#{out if opts[:show_ads]}", block.binding)
    concat("#{ads_slots('sideright') if opts[:show_ads]}</div></div>", block.binding)
    yield
    concat("</div>", block.binding)
  end
  
  def content_main(opts={}, &block)
    # opts = {:show_ads => true}.merge(opts)
    # @show_ads = opts[:show_ads]
    concat("<div class=\"container\" id=\"cmain\">", block.binding)
    yield
    concat("</div>", block.binding)
  end
  
  
  
  def mftext(title=nil, opts={}, &block)
    old_oddclass = @oddclass
    oddclass_reset
    opts[:additional_class] = opts[:additional_class] ? " #{opts[:additional_class]}" : nil
    grid_cls = opts[:grid] ? "grid-#{opts[:grid]}" : '' 
    glast_cls = 'glast' if opts[:glast]
    blast_cls = 'blast' if opts[:blast]
    out = "<div class=\"module mftext #{grid_cls} #{glast_cls} #{blast_cls} #{'sub-modules' if opts[:has_submodules]}\""
    out << " id=\"#{opts[:id]}\"" if opts[:id]
    concat(out << ">", block.binding)
    concat("<div class=\"mtitle#{opts[:additional_class]}\"><span>#{title}</span></div>", block.binding) if title
    concat("<div class=\"mcontent\">", block.binding)
    yield
    concat("</div></div>", block.binding)
    @oddclass = old_oddclass 
  end
  
  def mflistOLD(title, collection, options={}, &block)
    old_oddclass = @oddclass
    collection = collection.call if collection.respond_to? :call
    oddclass_reset
    grid_cls = options[:grid] ? "grid-#{options[:grid]}" : '' 
    glast_cls = 'glast' if options[:glast]
    blast_cls = 'blast' if options[:blast]
    class_cls = options[:class_container] if options[:class_container]
    return '' if collection.size == 0 && !options[:show_even_if_empty]
    out = "<div class=\"module mflist #{grid_cls} #{glast_cls} #{blast_cls} #{class_cls} \""
    out << " id=\"#{options[:id]}\"" if options[:id]
    concat(out << "><div class=\"mtitle mcontent-title\"><span>#{title}</span></div><div class=\"mcontent\"><ul>", block.binding)
    collection.each do |o|
      concat("<li class=\"#{oddclass} #{options[:class] if options[:class]} \">", block.binding)
      yield o
      concat("</li>", block.binding)
    end
    concat("</ul>", block.binding)
    concat(options[:bottom], block.binding) if options[:bottom]
    concat("</div></div>", block.binding)
    @oddclass = old_oddclass
  end
  
  def mftable(title, collection, options={}, &block)
    mfcontainer_list('table', title, collection, options, &block)
  end
  
    
  def mflist(title, collection, options={}, &block)
    mfcontainer_list('list', title, collection, options, &block)
  end
  
  def new_ads(opts={})
    # TODO
  end
  
  def mfcontainer_list(mode, title, collection, options={}, &block)
    old_oddclass = @oddclass
    collection = collection.call if collection.respond_to? :call
    oddclass_reset
    grid_cls = options[:grid] ? "grid-#{options[:grid]}" : '' 
    glast_cls = 'glast' if options[:glast]
    blast_cls = 'blast' if options[:blast]
    class_cls = options[:class_container] if options[:class_container]
    return '' if collection.size == 0 && !options[:show_even_if_empty]
    out = "<div class=\"module mf#{mode} #{grid_cls} #{glast_cls} #{blast_cls} #{class_cls} \""
    out << " id=\"#{options[:id]}\"" if options[:id]
    concat(out << "><div class=\"mtitle mcontent-title\"><span>#{title}</span></div><div class=\"mcontent\">", block.binding)
    concat(((mode == 'list') ? '<ul>' : '<table>'), block.binding)
    collection.each do |o|
      concat("<#{(mode == 'list') ? 'li' : 'tr'} class=\"#{oddclass} #{options[:class] if options[:class]} \">", block.binding)
      yield o
      concat("</#{(mode == 'list') ? 'li' : 'tr'}>", block.binding)
    end
    concat(((mode == 'list') ? '</ul>' : '</table>'), block.binding)
    concat(options[:bottom], block.binding) if options[:bottom]
    concat("</div></div>", block.binding)
    @oddclass = old_oddclass
  end
  
  def clan_link(clan)
    "<a href=\"#{gmurl(clan)}\">#{clan.name}</a>"
  end
  
  def mfcontent(content, &block)
    # TODO <% if @news.main_category.file then %><%=show_news_category_file(@news.main_category.file)%><% end %>
    out = <<-END
     <div class="module mfcontent"><div class="mtitle mcontent-title"><div class=\"iset iset#{content.class.name.downcase}\"></div> <span>#{show_rating_title(content)} #{content.resolve_hid}</span></div>
     <div class="mcontent">
    END
    if block
      concat(out, block.binding)
      out = ''
      yield
    else
      out<< <<-END
    #{"<div class=\"xdescription\">"<<auto_link(smilelize(content.description))<<"</div><br />" if content.respond_to?(:description) && content.description.to_s != ''}


#{"<div class=\"xmain\">"<<auto_link(smilelize(content.main))<<"</div>" if content.respond_to?(:main) && content.main.to_s != ''}
    END
      
    end
    if block
      concat("#{content_bottom(content)}</div></div>", block.binding)
    else
      out<< "#{content_bottom(content)}</div></div>"
    end
  end
  
  
  
  def mfcontents_summaries(title, object, find_args, opts={})
    # soporte show_day_separator
    #find_args.last[:include] = :user
    params['page'] = params['page'].to_i if params['page']
    opts[:pager].current_page = opts[:pager].last if params['page'].nil? && opts[:pager]    
    find_args[1][:limit] = opts[:pager].current.to_sql[0] if opts[:pager]
    find_args[1][:offset] = opts[:pager].current.to_sql[1] if opts[:pager]
    
    out = <<-END
    <div class="module mfcontents-summaries" id="#{opts[:id] if opts[:id]}">
  <div class="mtitle"><span>#{title}</span></div>
  <div class="mcontent">
    END
    
    out<< controller.send(:render_to_string, :partial => 'shared/pager', :object => opts[:pager], :locals => {:pos => 'top'}) if opts[:pager]
    
    cache_out = cache_without_erb_block(opts.fetch(:cache)) do 
      collection = object.find(*find_args)
      out2 = ' '
      if collection.size > 0 # no podemos hacer un return
        previous_day = nil
        collection = collection.reverse unless opts[:reverse] === false
        collection.reverse.each do |item|
          cur_day = Date.new(item.created_on.year, item.created_on.month, item.created_on.day)
          if cur_day != previous_day then 
            previous_day = Date.new(item.created_on.year, item.created_on.month, item.created_on.day)
            out2 << "<div class=\"day-separator\">#{print_tstamp(cur_day, 'date')}</div>"
          end
          
          out2<< <<-END
        <div class=\"mfcontents-summaries-item #{oddclass}\">
        <h2><a class=\"content\" href=\"#{get_url(item)}\">#{item.title}</a></h2>
        <div class="infoinline" style="line-height: 16px;">por #{link_to item.user.login, "#{gmurl(item.user)}", :class => 'nav' } | #{item.main_category.root.name} | #{print_tstamp(item.created_on, 'time')} | <span class="comments-count"><a title="Leer los comentarios de esta noticia" class="content" href="/noticias/show/#{item.id}#comments">#{item.cache_comments_count}</a></span></div>
          <div class="xdescription">#{auto_link(smilelize(item.description))}</div>
        </div>
          END
        end
      end
      out2
    end
    out<< cache_out if cache_out
    
    out<< controller.send(:render_to_string, :partial => 'shared/pager', :object => opts[:pager], :locals => {'pos' => 'bottom'}) if opts[:pager]
    out<< '</div></div>'
  end
  
  def mfcontents_basic(title, object, find_args, opts={})
    # TODO mostrar como is_read o no
    # TODO icono de facción
    # TODO limitar tamaño de title
    # TODO highlight_id
    # TODO downloads_count
    # TODO soporte rating
    # TODO soporte comments_count
    # TODO skip_id soporte para ocultar un id dado (por javascript) de forma que "Otras reviews" no muestre la review actual por accidente
    # TODO todas las llamadas deber:ian ser cacheadas
    if opts[:cache]
      cache_without_erb_block(opts[:cache]) { _mfcontents_basic(title, object, find_args, opts) }
    else
      _mfcontents_basic(title, object, find_args, opts)
    end
  end
  
  def cache_without_erb_block(name, &block)
    unless controller.perform_caching then block.call; return end
    if cache = controller.read_fragment(name, {})
      cache
    else
      buffer = block.call 
      pos = buffer.length
      block.call
      controller.write_fragment(name, block.call, {})
    end
  end
  
  def mfcontents_list_old(title, object, options={}, &block)
    raise "DEPRECATED"
    if object.class.name == 'Array'
      collection = object
    elsif object.respond_to?(:call)
      collection = object.call
    elsif object.respond_to?(:unique_content_id) 
      collection = object
    else
      collection = object.find(*find_args)
    end
    return '' if collection.size == 0
    old_oddclass = @oddclass
    oddclass_reset
    grid_cls = options[:grid] ? "grid-#{options[:grid]}" : '' 
    glast_cls = 'glast' if options[:glast]
    blast_cls = 'blast' if options[:blast]
    ids = []
    out = "<div class=\"module mfcontents-list #{grid_cls} #{glast_cls} #{blast_cls}\""
    out << " id=\"#{options[:id]}\"" if options[:id]
    concat(out << "><div class=\"mtitle mcontent-title\"><span>#{title}</span></div><div class=\"mcontent\"><ul>", block.binding)
    collection.each do |o|
      concat("<li #{'class="'<< options[:class] << '"' if options[:class]}>", block.binding)
      yield o
      concat("</li>", block.binding)
      ids<< o.unique_content.id
    end
    concat("</ul>", block.binding)
    concat('<script type="text/javascript">contents = contents.concat('<< ids.join(',') <<');</script>', block.binding)
    concat(options[:bottom], block.binding) if options[:bottom]
    concat("</div></div>", block.binding)
    @oddclass = old_oddclass 
  end
  
  def mfcontents_table(title, object, options={}, &block)
    mfcontents_thing('table', 'tr', title, object, options, &block)
  end
  
  def mfcontents_list(title, object, options={}, &block)
    mfcontents_thing('ul', 'li', title, object, options, &block)
  end
  
  def mfcontents_thing(container_tag, row_tag, title, object, options={}, &block)
    if object.class.name == 'Array'
      collection = object
    elsif object.respond_to?(:call)
      collection = object.call
    elsif object.respond_to?(:unique_content_id) 
      collection = object
    else
      collection = object.find(*find_args)
    end
    return '' if collection.size == 0
    old_oddclass = @oddclass
    oddclass_reset
    grid_cls = options[:grid] ? "grid-#{options[:grid]}" : '' 
    glast_cls = 'glast' if options[:glast]
    blast_cls = 'blast' if options[:blast]
    ids = []
    out = "<div class=\"module mfcontents-#{container_tag} #{grid_cls} #{blast_cls} #{glast_cls}\""
    out << " id=\"#{options[:id]}\"" if options[:id]
    concat(out << "><div class=\"mtitle\"><span>#{title}</span></div><div class=\"mcontent\"><#{container_tag}>", block.binding)
    collection.each do |o|
      concat("<#{row_tag} id=\"content#{o.unique_content.id}\" class=\"new #{oddclass} #{options[:class] if options[:class]}\">", block.binding)
      yield o
      concat("</#{row_tag}>", block.binding)
      ids<< o.unique_content.id
    end
    concat("</#{container_tag}>", block.binding)
    concat('<script type="text/javascript">contents = contents.concat('<< ids.join(',') <<');</script>', block.binding)
    concat(options[:bottom], block.binding) if options[:bottom]
    concat("</div></div>", block.binding)
    @oddclass = old_oddclass 
  end
  
  def _mfcontents_basic(title, object, find_args, opts={})
    opts = {:truncate_at => 30}.merge(opts)
    if object.class.name == 'Array'
      collection = object
    elsif object.respond_to?(:call)
      collection = object.call
    elsif object.respond_to?(:unique_content_id) 
      collection = object
    else
      collection = object.find(*find_args)
    end
    return '' if collection.size == 0
    old_oddclass = @oddclass
    oddclass_reset
    grid_cls = opts[:grid] ? "grid-#{opts[:grid]}" : '' 
    glast_cls = 'glast' if opts[:glast]
    blast_cls = 'blast' if opts[:blast]
    ids = []
    out = <<-END
        <div class="module mfcontents-basic #{grid_cls} #{glast_cls} #{blast_cls}">
        <div class="mtitle"><span>#{title}</span></div>
        <div class="mcontent">
        <ul>
        END
    collection.each do |item|
      ids<< item.unique_content.id
      out<< "<li class=\"new #{oddclass}\" id=\"content#{item.unique_content.id}\"><a title=\"#{tohtmlattribute(item.title)}\" href=\"#{get_url(item)}\">"
      out<< draw_content_favicon(item) if opts[:faction_favicon]
      out<< "#{truncate(item.title, opts[:truncate_at], '..')}</a></li>"
    end
    out<< '</ul>'
    out<< '<script type="text/javascript">contents = contents.concat('<< ids.join(',') <<');</script>'
    out<< opts[:more_link] if opts[:more_link]
    out<< '
  </div>
</div>'
    @oddclass = old_oddclass 
    out
  end
  
  def draw_content_favicon(item)
    "<div class=\"content-category\">#{faction_favicon(item)}</div>" 
  end
  
  def hue_selector(id, field_name, v)
    out = <<-END
    <div id="#{id}-hue-preview" style="width: 16px; height: 16px; float: left; border: 1px solid black;"></div> 
    <input type="text" class="text" name="#{field_name}" value="#{v}" onclick="$j('##{id}-hue-selector').removeClass('hidden');" />
<div id="#{id}-hue-selector" class="hidden"><img src="/images/hue_selector.png" onclick="cpMouseClick" /></div>
<script type="text/javascript">$j('##{id}-hue-selector img').onclick = cpMouseClick;
    END
    
    if v then
      out<< <<-END
        $j('##{id}-hue-preview').css('background', hsv2rgb(Math.round(#{v}), 100, 100));
      END
    end
    out<< '</script>'
  end
  
  
  def rgbcolor_selector(id, field_name, v)
    out = <<-END
      <div id="#{id}-hue-preview" style="width: 16px; height: 16px; float: left; border: 1px solid black;"></div> <input id="#{id}-hue-input" type="text" class="text" name="#{field_name}" value="#{v.to_s.gsub('#', '')}" />
<script type="text/javascript">
attachColorPicker(document.getElementById('#{id}-hue-input'));
    END
    
    if v then 
      out<< <<-END
          $j('##{id}-hue-preview').css('background', '##{v.gsub('#','')}');
        END
    end
    out<< '</script>'
  end
  
  def percent_selector(id, field_name, v)
    <<-END
      <input type="text" class="text" name="#{field_name}" value="#{v}" />
    END
  end
  
  def string_selector(id, field_name, v)
    "STRING_SELECTOR_NOT_YET_IMPLEMENTED"
  end
  
  # columns es un hash de titulos de columnas como keys y o bien symbols o bien procs como valores
  def xdelitems(collection, form_destination, input_name, columns, options={})
    options = {:submit_value => 'Enviar'}.merge(options)
    out = <<-END
    <form method="post" action="#{form_destination}"><table><tr><th><input type="checkbox" onclick="slnc.checkboxSwitchGroup(this);"></th>
  END
    columns.keys.each do |k|
      out<< "<th>#{k}</th>"
    end
    out<< '</tr>'
    collection.each do |item|
      out<< "<tr class=\"#{oddclass}\"><td><input type=\"checkbox\" name=\"#{input_name}[]\" onclick=\"slnc.hilit_row(this, 'selrow');\" value=\"#{item.id}\" /></td>"
      columns.each do |k,v|
        if v.kind_of?(Proc)
          out<< "<td>#{v.call(item)}</td>"
        elsif v.kind_of?(Symbol)
          out<< "<td>#{item.send(v)}</td>"
        else
          raise "#{v.class.name} is not valid for xdelitems"
        end
      end
      out<< '</tr>'
    end
    out<< "</table>
    <input type=\"submit\" onclick=\"return confirm('¿Estás seguro?');\" value=\"#{options[:submit_value]}\" /></form>"
  end
  
  def faction_activity_minicolumns(faction)
    # TODO esto no lo cachearan algunos browsers, usar .1.png
    "<img title=\"Karma generado durante el último mes en #{faction.code} (1 día una columna)\" class=\"minicolumns\" src=\"/storage/minicolumns/factions_activity/#{faction.id}.png?d=#{Time.now.strftime('%Y-%m-%d')}\" />"
  end
  
  def minicolumns(mode, data)
    mc_id = "minicols_{mode}#{data.join(',')}"
    f = "#{RAILS_ROOT}/public/storage/minicolumns/#{mc_id}.png"
    Cms.gen_minicolumns(mode, data, f) unless File.exists?(f)
    "<img src=\"/storage/minicolumns/#{mc_id}.png\" />"
  end
  
  def winner_cup(winner)
    "<img src=\"/images/blank.gif\" class=\"competition-cup cup#{winner}\" />"
  end
  
  def faction_cohesion(faction=@faction)
    "#{(faction.member_cohesion * 1000).to_i.to_f / 10}%"
  end
  
  @@_cache_ads_slots = {}
  @@_cache_ads_slots_time = nil
  
  def ads_slots(location, game_id=nil)
    @@_cache_ads_slots_time = controller.global_vars['ads_slots_updated_on'] if @@_cache_ads_slots_time.nil?
    if controller.global_vars['ads_slots_updated_on'] > @@_cache_ads_slots_time
      @@_cache_ads_slots = {}
      @@_cache_ads_slots_time = controller.global_vars['ads_slots_updated_on']
    end
    cache_key = "#{controller.portal.id}-#{location}-#{game_id}"
    @@_cache_ads_slots[cache_key] ||= AdsSlot.find(:all, :conditions => ["location = ? 
                                    AND id IN (select id 
                                                 from ads_slots 
                                                where id not in (select ads_slot_id 
                                                                   from ads_slots_portals) 
                                                UNION select id 
                                                                   from ads_slots 
                                                                  where id in (select ads_slot_id 
                                                                                 from ads_slots_portals 
                                                                                where portal_id = #{controller.portal.id}))", location], :order => 'position')
    out = ''
    @@_cache_ads_slots[cache_key].each do |asl|
      asi = asl.get_ad(game_id)
      if asi
        params['_xad'] << asi.id.to_s
        out << "<div class=\"adslot\">#{asi.ad.ad_html(asi.id, asl.image_dimensions)}</div>"
      end
    end
    out
  end
end
