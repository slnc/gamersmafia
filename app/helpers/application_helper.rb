# -*- encoding : utf-8 -*-
require 'rails_rinku'

module ApplicationHelper
  ANALYTICS_SNIPPET = <<-END
<script type="text/javascript">
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-130555-1']);
  _gaq.push(['_setDomainName', '.gamersmafia.com']);
  _gaq.push(['_trackPageview']);
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
</script>
  END

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

  # Keep this in sync with app/assets/fonts/gm_icons.svg
  GM_ICONS = {
    "star" => "&#xe000;",
    "stats" => "&#xe001;",
    "gmf" => "&#xe002;",
    "emblem-common" => "&#xe003;",
    "emblem-legendary" => "&#xe004;",
    "emblem-rare" => "&#xe005;",
    "emblem-special" => "&#xe006;",
    "emblem-unfrequent" => "&#xe007;",
    "user" => "&#xe008;",
    "message" => "&#xe009;",
    "flag" => "&#xe00a;",
    "scale" => "&#xe00b;",
    "gear" => "&#xe00c;",
    "gauntlet" => "&#xe00d;",
  }

  WMENU_POS = {
    'arena' => %w(
        Admin::CompeticionesController
        ArenaController
    ),
    'bazar' => %w(
        Cuenta::TiendaController
        BazarController
    ),
    'foros' => %w(ForosController),
    'hq' => %w(
        Admin::CategoriasController
        Admin::ClanesController
        Admin::CategoriasfaqController
        Admin::EntradasfaqController
        Admin::FaccionesController
        Admin::IpBansController
        Admin::MapasJuegosController
        Admin::UsuariosController
        AdministrationController
        AvataresController
    ),
    'comunidad' => %w(
        Cuenta::Clanes::GeneralController
        ReclutamientoController
        ComunidadController
    )
  }

  # Class-level array for fast lookups
  WMENU_POS_BY_CONTROLLER = begin
    out = {}
    WMENU_POS.each do |k,v|
      v.each do |controller_name|
        out[controller_name] = k
      end
    end
    out
  end

  def droparea
    <<-END
      <div class="droparea">arrastra imágenes aquí</div>
      <div id="dropped-files" class="image-gallery-sm"></div>
      <div class="image-editor hidden">
        <canvas class="hidden"></canvas>
        <img src="/images/dot.png" class="image2" />
      </div>
    END
  end

  def quicklinks
    if user_is_authed
      # TODO(slnc): PERF cache this
      interests = @user.user_interests.show_in_menu.find(:all).collect {|i|
        {:code => i.entity_name, :url => gmurl(i.real_item)}
      }
      (interests + Personalization.quicklinks_for_user(@user)).sort_by{|i|
        i[:code].downcase
      }
    else
      Personalization.get_default_quicklinks
    end
  end

  def bool_to_str(bool)
    bool ? "Sí" : "No"
  end

  def js_trigger_content_init
    """<script type=\"text/javascript\">$(document).ready(function() {
    Gm.triggerContentInit();
    });
    </script>
    """
  end

  def home_image(home_image_url)
    return '' if home_image_url.to_s == ''
    "<img class=\"home-image\" src=\"/#{home_image_url}\" />"
  end

  def positive_negative_bar(negative_count, neutral_count, positive_count)
    max = [negative_count, neutral_count, positive_count].sum
    pcent_negative = negative_count.to_f / max
    pcent_positive = positive_count.to_f / max
    "<div class=\"positive-negative-bar\">#{draw_pcent_bar(pcent_negative, nil, nil, nil, css_class='align-right negative-bar-bg')}#{draw_pcent_bar(pcent_positive, nil, nil, nil, css_class='positive-bar-bg')}</div>"
  end

  def term_with_context(term)
    case term.taxonomy
    when "ContentsTag"
      "#{term.name} (tag)"
    when "DownloadsCategory"
      "#{term.name} &laquo; #{term.get_ancestors.collect {|a| a.name}.join("&laquo;")}"
    when "EventsCategory"
      "#{term.name} &laquo; #{term.get_ancestors.collect {|a| a.name}.join("&laquo;")}"
    when "ImagesCategory"
      "#{term.name} &laquo; #{term.get_ancestors.collect {|a| a.name}.join("&laquo;")}"
    when "NewsCategory"
      "#{term.name} &laquo; #{term.get_ancestors.collect {|a| a.name}.join("&laquo;")}"
    when "QuestionsCategory"
      "#{term.name} &laquo; #{term.get_ancestors.collect {|a| a.name}.join("&laquo;")}"
    when "TopicsCategory"
      "#{term.name} &laquo; #{term.get_ancestors.collect {|a| a.name}.join("&laquo;")}"
    when "TutorialsCategory"
      "#{term.name} &laquo; #{term.get_ancestors.collect {|a| a.name}.join("&laquo;")}"
    when nil
      term.name
    else
      raise "Term taxonomy '#{term.taxonomy}' unknown."
    end
  end

  def s_content_list(contents)
    out = []
    contents.each do |content|
      out  << controller.send(
          :render_to_string,
          :partial => '/contents/headline',
          :locals => { :content => content }).force_encoding("utf-8")
    end
    out.join("\n")
  end

  def s_gmurl(object)
    case object.class.name
    when 'Content'
      content_path(object)
    end
  end

  def analytics_code
    ApplicationHelper::ANALYTICS_SNIPPET
  end

  def pluralize_on_count(word, count)
    if (count == 1)
      word
    else
      if /\w de \w/ =~ word
        split_word = word.split(" ")
        "#{pluralize_on_count(split_word[0], count)} de #{split_word[2]}"
      elsif !%w(a e i o u w g c).include?(word[-1])
        "#{word}es"
      else
        "#{word}s"
      end
    end
  end

  def gm_translate(word)
    Translation.translate(word)
  end

  def portal_code
    controller.portal_code
  end

  def sawmode
    @sawmode ||= begin
      if user_is_authed then
        if @user.has_skill?("Webmaster")
          sawmode = 'full'
        elsif Authorization.is_advertiser?(@user)
          sawmode = 'anunciante'
        else
          sawmode = ''
        end
      else
        sawmode = ''
      end
    end
  end

  def skill_needed_disclaimer(skill_name)
    "Necesitas la <a href=\"/cuenta/cuenta/habilidades\">habilidad #{skill_name}
    </a> para poder acceder a esta sección."
  end

  # Global var shortcut function
  def global_var(var_name)
    controller.global_vars[var_name]
  end

  def body_css_classes
    classes = %w(lydefault)
    classes<< "has-submenu" if controller.submenu
    if user_is_authed
      classes<< "user-authed"
    else
      classes<< "user-anonymous"
    end
    classes<< "co#{controller.controller_path.gsub('/', '-').gsub('_', '-')}"
    classes<< "v#{params[:action].to_s.split('/').last}"

    classes.join(" ")
  end

  def render_content_contents(content)
    case content.class.name
    when "Image"
      partial = '/contenidos/image'
    else
      partial = '/contenidos/base'
    end
    controller.send(
        :render_to_string,
        :partial => partial, :locals => {:content => content})
  end

  def observe_field(field, opts={})
    out = <<-END
      jQuery(function($) {
        $("##{field}").change(function() {
          $.get("#{opts[:url]}", function(data) {
            $("##{opts[:update]}").html(data);
          });
        });
      })
    END
  end

  def should_show_bottom_ad?
    if controller.no_ads
      false
    elsif !user_is_authed || @user.created_on > 1.year.ago
      true
    end
  end

  def active_sawmode
    if controller.active_sawmode
      @active_sawmode
    else
      WMENU_POS[controller.controller_name] || ''
    end
  end

  QUICKLINK_ENABLED_PORTALS = %w(FactionsPortal BazarDistrictPortal)

  def can_add_as_quicklink?
    return false if !quicklinks_enabled_current_user_portal
    !current_portal_is_quicklink
  end

  def can_del_quicklink?
    return false if !quicklinks_enabled_current_user_portal
    current_portal_is_quicklink
  end

  def error_messages_for(obj)
    return "" unless obj && obj.errors.any?
    out = ""
    out << "<ul>"
    obj.errors.full_messages.each do |msg|
      out << "<li>#{msg}</li>"
    end
    out << "</ul>"
  end

  def can_add_as_user_forum?
    return false if !user_forums_enabled?
    !user_forum_is_present
  end

  def can_del_user_forum?
    return false if !user_forums_enabled?
    user_forum_is_present
  end

  def url_for_content(object, text)
    old_content_url = Routing.url_for_content_onlyurl(object)
    "<a class=\"content\" href=\"#{old_content_url}\">#{text}</a>"
  end

  def css_image_selector(field_name, field_value, skin)
    cls_string = field_value == 'none' ? 'selected="selected"' : ''

    out = <<-END
  <select name="#{field_name}">
<option value="">(por defecto)</option>
<option #{cls_string} value="none">(ninguna)</option>
    END

    skin.skins_files.each do |sfn|
      val = "url(/#{sfn.file})"
      out << <<-END
        <option #{'selected="selected"' if val == field_value } value="#{val}">#{File.basename(sfn.file)}</option>
      END
    end

    out << '</select>'
  end

  def css_background_repeat(field_name, field_value, skin)
    out = <<-END
  <select name="#{field_name}">
  <option #{'selected="selected"' if field_value == 'inherit' } value="inherit">(por defecto)</option>
  <option #{'selected="selected"' if field_value == 'no-repeat' } value="no-repeat">no repetir</option>
  <option #{'selected="selected"' if field_value == 'repeat-y' } value="repeat-y">repetir en vertical</option>
  <option #{'selected="selected"' if field_value == 'repeat-x' } value="repeat-x">repetir en horizontal</option>
  <option #{'selected="selected"' if field_value == 'repeat' } value="repeat">repetir en ambas direcciones</option>
    END

    out << '</select>'
  end

  def css_background_position(field_name, field_value, skin)
    out = <<-END
  <select name="#{field_name}">
  <option #{'selected="selected"' if field_value == 'inherit' } value="inherit">(por defecto)</option>
  <option #{'selected="selected"' if field_value == 'top left' } value="top left">top left</option>
  <option #{'selected="selected"' if field_value == 'top center' } value="top center">top center</option>
  <option #{'selected="selected"' if field_value == 'top right' } value="top right">top right</option>
  <option #{'selected="selected"' if field_value == 'center left' } value="center left">center left</option>
  <option #{'selected="selected"' if field_value == 'center center' } value="center center">center center</option>
  <option #{'selected="selected"' if field_value == 'center right' } value="center right">center right</option>
  <option #{'selected="selected"' if field_value == 'bottom left' } value="bottom left">bottom left</option>
  <option #{'selected="selected"' if field_value == 'bottom center' } value="bottom center">bottom center</option>
  <option #{'selected="selected"' if field_value == 'bottom right' } value="bottom right">bottom right</option>

    END

    out << '</select>'
  end

  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end

  def color_selector(field_name, field_value)
    field_id = "colorSelectorField#{field_name.gsub('[', '').gsub(']', '')}"
    div_sel_id = "colorSelector#{field_name.gsub('[', '').gsub(']', '')}"
  <<-END
  <div id="#{div_sel_id}" style="width: 20px; height: 20px; float: left; border: 1px solid black; margin-right: 5px;"><div style="width: 100%; height: 100%;"></div></div> <input name="#{field_name}" id="#{field_id}" value="#{field_value}" />

<script type="text/javascript">
$(document).ready(function () {
$('##{field_id}').ColorPicker({
  color: '#0000ff',
  onShow: function (colpkr) {
    $(colpkr).fadeIn(100);
    return false;
  },
  onHide: function (colpkr) {
    $(colpkr).fadeOut(100);
    return false;
  },
  onBeforeShow: function () {
    $(this).ColorPickerSetColor(this.value);
  },
  onChange: function (hsb, hex, rgb) {
    $('##{div_sel_id} div').css('backgroundColor', '#' + hex);
    $('##{field_id}').val('#' + hex);
  }
});
$('##{div_sel_id} div').css('backgroundColor', $('##{field_id}').val()); });
</script>
    END
  end

  def bbeditor(opts={})
    raise "id not given for bbeditor" unless opts[:id]
    raise "name not given for bbeditor" unless opts[:name]

    if user_is_authed && @user.pref_use_elastic_comment_editor.to_i == 1
      opts[:class] ||= ""
      opts[:class] += " elastic"
    end

    out = <<-EOS
    <div title="Negrita" class="btn bold"></div>
    <div title="Cursiva" class="btn italic"></div>
    <div title="Enlace" class="btn link"></div>
    <div title="Quote" class="btn quote"></div>
    <div title="Código (bash,cpp,csharp,css,java,perl,php,python,ruby,sql,vb,xml)" class="btn code"></div>
    <div title="Imagen" class="btn image"></div>
    <div title="Deshacer" class="btn back"></div>
    <div title="Rehacer" class="btn forward"></div>
    <div class="clearb">
      <textarea id="#{opts[:id]}" class="bbeditor #{opts[:class]}" name="#{opts[:name]}" rows="#{opts[:rows]}" style="#{opts[:style]}">#{opts[:value]}</textarea></div>
    EOS

    out << <<-EOS
    #{controller.send(:render_to_string, :partial => '/shared/smileys', :locals => { :dom_id => opts[:id] }).force_encoding("utf-8")}
    EOS
    out.force_encoding("utf-8")
  end

  def draw_emblem(emblema)
    "<img class=\"sprite1 emblema emblema-#{emblema}\" src=\"/images/blank.gif\" />"
  end

  def sparkline(opts)
    # req: data size
    opts = {:colors => ['0077cc'], :fillcolors => ['E6F2FA']}.merge(opts)
    out = ''
    spid = Digest::MD5.hexdigest((Time.now.to_i + Kernel.rand).to_s)
    # load_javascript_lib('web.shared/jgcharts-0.9')
    out << "<div id=\"line#{spid}\"></div>
<script type=\"text/javascript\">
$(document).ready(function() {
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
    spid = Digest::MD5.hexdigest((Time.now.to_i + Kernel.rand).to_s)
    # load_javascript_lib('web.shared/jgcharts-0.9')
    out << "<div id=\"line#{spid}\"></div>
<script type=\"text/javascript\">
$(document).ready(function() {
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
    spid = Digest::MD5.hexdigest((Time.now.to_i + Kernel.rand).to_s)
    # load_javascript_lib('web.shared/jgcharts-0.9')
    out << "<div id=\"line#{spid}\"></div>
<script type=\"text/javascript\">
$(document).ready(function() {
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
    concat("<div class=\"container c2colx\">".force_encoding("utf-8"))
    yield
    concat("</div>")
  end

  def content_3col(&block)
    concat("<div class=\"container c3col\">".force_encoding("utf-8"))
    yield
    concat("</div>")
  end

  def content_3colx(&block)
    concat("<div class=\"container c3colx\">".force_encoding("utf-8"))
    yield
    concat("</div>")
  end

  def content_3coly(&block)
    concat("<div class=\"container c3coly\">".force_encoding("utf-8"))
    yield
    concat("</div>")
  end

  def gmurl(object, opts={})
    Routing.gmurl(object, opts)
  end

  def member_state(state)
    "<img class=\"sprite1 member-state #{state}\" src=\"/images/blank.gif\" />"
  end

  def user_link(user, opts={})
    opts = {:avatar => false}.merge(opts)
    out = ''
    if opts[:avatar] then
      # avatar y link en negrita
      out << "<img style=\"float: left; margin-right: 5px;\" class=\"avatar\" src=\"#{user.show_avatar}\" /> <strong><a href=\"#{gmurl(user)}\">#{user.login}</a></strong>"
    else
      out << "<a class=\"user-link\" href=\"#{gmurl(user)}\">#{user.login}</a>"
    end
    out
  end

  def comments_icon(name, desp=false)
    vdesp = desp ? '547' : '559'
    '<img alt="' << "#{name}" << '" title="' << "#{name}" << '" class="sprite1 comments-icon" src="/images/blank.gif" style="background-position: -' << COMMENTS_DESPL[name] << 'px -' << vdesp << 'px;" />'
  end

  def notags(txt)
    txt.to_s.gsub('<', '&lt;').gsub('>', '&gt;')
  end

  def faction_favicon(thing)
    Cms.faction_favicon(thing)
  end

  def content_category(thing)
    "<div class=\"sprite1 content-category\">#{faction_favicon(thing)}</div>"
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

    text.gsub!('<br />', "SALTOLINEA333\n") if text.index('<p>').to_s == ''

    text.gsub!(/\r\n/, "\n")
    text.gsub!(/\r/, "\n")
    text = Cms.add_p(text) if text.index('<p>').to_s == '' # si tiene <p> suponemos que está bien formateado ya
    text = " #{text}"
    text = Formatting.add_smileys(text)

    if text.index('SALTOLINEA333').to_s != '' then
      text.gsub!("SALTOLINEA333\n", '</p><p>')
      text.gsub!("SALTOLINEA333", '')
      text = "#{text}</p>"
      text = text.gsub('<p></p>', '')
      text = text.gsub('<p><p>', '<p>')
      text = text.gsub('</p></p>', '</p>')
    end
    text = text.gsub('<blockquote></p><p>', '<blockquote>')
    text = text.gsub('</p><p></blockquote>', '</blockquote>')
    text = text.gsub('<code></p><p>', '<code>')
    text = text.gsub('</p><p></code>', '</code>')

    text.strip!

    text
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

  def draw_pcent_bar(pcent, text=nil, compact=false, color=nil, css_class='')
    if pcent.nil?
      Rails.logger.warn(
          "draw_pcent_bar(nil, #{text}, #{compact}, #{color}). Using 0" +
          " instead of nil.")
      pcent = 0
    end
    # 0 <= pcent <= 1
    if (pcent.kind_of?(Float) && pcent.nan? ) || pcent.to_f == Infinity
      pcent = 0
    elsif pcent > 1.0
      pcent = 1.0
    end

    # text = "%.2f" % pcent if text == nil
    text = "#{(pcent*100).to_i}%" if text == nil

    "<div class=\"pcent-bar#{(compact)?' compact':''} #{css_class}\"><img src=\"/images/blank.gif\" title=\"#{text}\" class=\"bar\" style=\"width: #{(pcent*100).to_i}%; #{'background-color: ' + color + ';' if color}\" /></div>"
  end

  def draw_rating(rating_h)
    rating_points = rating_h[0]
    if rating_points.nil?
      src = 'grey'
      text = 'No hay suficientes valoraciones'
    else
      src = rating_points
      text = "Valoración: #{src}"
    end

    "<span class=\"rating stars#{src}\"><span class=\"sprite1\"><img alt=\"#{text}\" title=\"#{text} (#{rating_h[1]} valoraciones)\" src=\"/images/blank.gif\" width=\"64\" height=\"13\" /></span></span>"
  end

  def draw_contentheadline(content)
    "<div class=\"infoinline\">#{print_tstamp(content.created_on)} | #{draw_rating(content.rating)} | <span class=\"comments-count\"><a title=\"Ver comentarios\" href=\"#{Routing.url_for_content_onlyurl(content)}\#comments\">#{content.unique_content.comments_count}</a></span></div>"
  end

  def draw_organization_building(org, stories=1)
    if org.has_building?
      bldgs = [org.building_top, org.building_middle, org.building_bottom]
    else
      bldgs = ['images/building_top.png', 'images/building_middle.png', 'images/building_middle.png']
    end

    out = "<div style=\"margin: 2px;\"><img src=\"/#{bldgs[0]}\" /><br />"
    stories.times do
      out << "<img src=\"/#{bldgs[1]}\" /><br />"
    end
    out << "<img src=\"/#{bldgs[2]}\" /></div>"
  end

  def gmd10
    '<img class="gmd10 sprite1" alt="Dólares GM" src="/images/blank.gif" />'
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
    for competition in Competition.related_with_user(@user)
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
    opts[:width] ||= '550px'


    load_javascript_lib('ckeditor')
      <<-END
        <textarea name="#{field_name}">#{opts[:value]}</textarea><br />
				<script type="text/javascript">
				//<![CDATA[
					CKEDITOR.replace( '#{field_name}', {
height: '#{opts[:height]}',
width: '#{opts[:width]}',
skin: 'v2'
}
 );
				//]]>
				</script>
      END
  end

  def load_javascript_lib(lib)
    @_additional_js_libs ||= []
    @_additional_js_libs << lib
  end

  def get_last_commented_contents
    if controller.portal_code && controller.portal.class.name == 'FactionsPortal'
      ids = [0] + controller.portal.games.collect { |g| g.id }
      contents = Content.find(:all, :conditions => "comments_count > 0 and is_public = 't' AND ((game_id is null AND clan_id IS NULL) OR game_id IN (#{ids.join(',')}))", :order => 'updated_on DESC', :limit => 25)
    else
      contents = Content.find(:all, :conditions => "comments_count > 0 and is_public = 't' AND ((game_id is null AND clan_id IS NULL) OR game_id IS NOT NULL)", :order => 'updated_on DESC', :limit => 25)
    end
    contents.collect { |c| c.real_content }
  end


  def content_bottom(obj)
    if user_is_authed && obj.state == Cms::PENDING && obj.class.name != 'Blogentry' && @user.id != obj.user_id
      controller.send(:render_to_string, :partial => '/shared/accept_or_deny', :locals => { :object => obj }).force_encoding("utf-8")
    elsif [Cms::PUBLISHED, Cms::DELETED, Cms::ONHOLD].include?(obj.state)
      out = controller.send(:render_to_string, :partial => 'shared/contentinfobar', :locals => { :object => obj }).force_encoding("utf-8")
      out<< controller.send(:render_to_string, :partial => 'shared/comments', :locals => { :object => obj }).force_encoding("utf-8")
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
    if obj.state.nil? || obj.state == Cms::DRAFT
      "<p><label><input type=\"checkbox\" name=\"draft\" value=\"1\" #{'checked=\"checked\"' if (obj.state == Cms::DRAFT && !obj.new_record?) }/> Borrador</label></p>"
    end
  end

  def suicidal_enabled?
    @suicidal
  end

  def javascript_includes
    out = ""

    if @_additional_js_libs
      @_additional_js_libs.uniq.each do |lib|
        if lib == 'ckeditor'
          out << "<script src=\"#{ASSET_URL}/ckeditor/ckeditor.js\" type=\"text/javascript\"></script>"
        elsif lib.include?('http://')
          out << "<script src=\"#{lib}\" type=\"text/javascript\"></script>"
        else
          out << <<-END
<script src="#{ASSET_URL}/javascripts/#{lib}.#{'pack.' if App.compress_js?}#{AppR.ondisk_git_version}.js" type="text/javascript"></script>
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
      when 'Facción'
      if controller.class.name.include?('Cuenta')
        "Mi Facción"
      else
        'Facción'
      end
      when 'Clan'
      "Mis Clanes"
    else
      ActiveSupport::Inflector::humanize(ActiveSupport::Inflector::tableize(controller.submenu))
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
    firstlevelname = "Portada #{controller.portal.code}" # controller.active_sawmode ? controller.active_sawmode.titleize : 'Portada'
    out<< "<li class=\"home\"><a title=\"Ir a portada\" class=\"sprite1 nav\" href=\"/\"><span>#{firstlevelname}</span></a></li>"
    if @navpath # TODO oldschool navpath, remove all of 'em
      #return '' if @navpath.size == 1
      last = @navpath.pop # TODO remove pop directamente en todos los controllers y quitar aquí (a la vez)
      @navpath.each { |np_name, np_url| out<< "<li><a class=\"sprite1 nav\" href=\"#{np_url}\">#{np_name}</a></li>" unless np_name == 'Application'}
      out<< "<li class=\"current sprite1\">#{last[0]}</li>" if last
    elsif controller.controller_name != 'home' && controller.navpath2 then
      #return '' if controller.navpath2.size == 1
      controller.navpath2.each { |np_name, np_url| out<< "<li><a class=\"sprite1 nav\" href=\"#{np_url}\">#{np_name}</a></li>"  unless np_name == 'Application' }
      out<< "<li class=\"current sprite1\">#{controller.title}</li>"
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
      out<< "<div id=\"content-stats2\" class=\"content-rating\" class=\"centered\">#{draw_rating(obj.rating)}</div>"
      out<< '</div>'
    end
  end

  def show_rating(obj)
    if obj.is_public?
      out = "<div id=\"content-stats\">"
      out<< "<div class=\"content-rating\" class=\"centered\">#{draw_rating(obj.rating)}<br /><span class=\"infoinline\">(#{obj.rating[1]} valoraciones)</span></div>"
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
    raise "opts[:content] not given!" unless opts[:content]
    generic_support(opts) do
      block.call
      #raise controller.render_to_string(:partial => '/shared/content_tag_browser', :locals => { :content => opts[:content] })
      concat(controller.send(:render_to_string, :partial => '/shared/content_tag_browser', :locals => { :content => opts[:content] }).force_encoding("utf-8"))
    end
  end

  def generic_support(opts={}, &block)
    opts = {:show_ads => true}.merge(opts)
    return '' if controller.portal.kind_of?(ClansPortal)
    out = ''

    concat("<div class=\"container\" id=\"csupport\"><div class=\"ads-slots\"><div class=\"ads-slots1\">#{out if opts[:show_ads]}".force_encoding("utf-8"))
    concat("#{ads_slots('sideright') if opts[:show_ads]}</div></div>")
    yield
    concat("</div>")
  end

  def content_main(opts={}, &block)
    concat("<div class=\"container\" id=\"cmain\">".force_encoding("utf-8"))
    yield
    concat("</div>")
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
    concat(out << ">".force_encoding("utf-8"))
    concat("<div class=\"mtitle#{opts[:additional_class]}\"><span>#{title}</span></div>".force_encoding("utf-8")) if title
    concat("<div class=\"mcontent\">")
    yield
    concat("</div></div>")
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
    concat(out << "><div class=\"mtitle mcontent-title\"><span>#{title}</span></div><div class=\"mcontent\"><ul>".force_encoding("utf-8"))
    collection.each do |o|
      concat("<li class=\"#{oddclass} #{options[:class] if options[:class]} \">")
      yield o
      concat("</li>")
    end
    concat("</ul>")
    concat(options[:bottom]) if options[:bottom]
    concat("</div></div>")
    @oddclass = old_oddclass
  end

  def mftable(title, collection, options={}, &block)
    mfcontainer_list('table', title, collection, options, &block)
  end


  def mflist(title, collection, options={}, &block)
    mfcontainer_list('list', title, collection, options, &block)
  end

  def new_ads(opts={})
  end

  def mfcontainer_list(mode, title, collection, options={}, &block)
    old_oddclass = @oddclass
    collection = collection.call if collection.respond_to? :call
    oddclass_reset
    grid_cls = options[:grid] ? "grid-#{options[:grid]}" : ''
    glast_cls = 'glast' if options[:glast]
    blast_cls = 'blast' if options[:blast]
    class_cls = options[:class_container] if options[:class_container]
    if collection.size == 0 && options[:message_on_empty].nil? && !options[:show_even_if_empty]
      return ''
    end
    out = "<div class=\"module mf#{mode} #{grid_cls} #{glast_cls} #{blast_cls} #{class_cls} \""
    out << " id=\"#{options[:id]}\"" if options[:id]
    concat(out << "><div class=\"mtitle #{'mcontent-title' unless options[:no_mcontent_title]}\"><span>#{title}</span></div><div class=\"mcontent\">".force_encoding("utf-8"))

    if collection.size == 0 && options[:message_on_empty]
      concat(options[:message_on_empty])
    end

    concat(((mode == 'list') ? '<ul>' : '<table>'))
    collection.each do |o|
      concat("<#{(mode == 'list') ? 'li' : 'tr'} class=\"#{oddclass} #{options[:class] if options[:class]} \">")
      yield o
      concat("</#{(mode == 'list') ? 'li' : 'tr'}>")
    end
    concat(((mode == 'list') ? '</ul>' : '</table>'))
    concat(options[:bottom]) if options[:bottom]
    concat("</div></div>")
    @oddclass = old_oddclass
  end

  def clan_link(clan)
    "<a href=\"#{gmurl(clan)}\">#{clan.name}</a>"
  end

  def auto_link_raw(input)
    auto_link(input, :sanitize => false)
  end

  def mfcontent(content, &block)
    out = <<-END
     <div class="module mfcontent"><div class="mtitle mcontent-title"><div class=\"iset iset#{content.class.name.downcase}\"></div> <span>#{show_rating_title(content)} #{content.resolve_hid}</span></div>
     <div class="mcontent">
    END
    out.force_encoding("utf-8")
    if block
      concat(out)
      out = ''.force_encoding("utf-8")
      yield
    else
      out<< <<-END
    #{"<div class=\"xdescription\">"<<auto_link_raw(smilelize(content.description))<<"</div><br />" if content.respond_to?(:description) && content.description.to_s != ''}


#{"<div class=\"xmain\">"<<auto_link_raw(smilelize(content.main))<<"</div>" if content.respond_to?(:main) && content.main.to_s != ''}
      END
    end

    if block
      concat("#{content_bottom(content)}</div></div>")
    else
      out<< "#{content_bottom(content)}</div></div>"
    end
  end



  def mfcontents_summaries(title, object, find_args, opts={})
    # soporte show_day_separator
    #find_args.last[:include] = :user
    out = <<-END
    <div class="module mfcontents-summaries" id="#{opts[:id] if opts[:id]}">
  <div class="mtitle"><span>#{title}</span></div>
  <div class="mcontent">
    END

    page = 1 if page.to_i == 0
    original_collection = object.paginate(find_args)

    out<< controller.send(
        :render_to_string,
        :partial => 'shared/pager2',
        :locals => {:collection => original_collection, :pos => 'top'}).force_encoding("utf-8")

    collection = original_collection.clone
    cache_out = cache_without_erb_block(opts.fetch(:cache)) do
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
        <h2><a class=\"content\" href=\"#{gmurl(item)}\">#{item.title}</a></h2>
        <div class="infoinline" style="line-height: 16px;">por #{link_to item.user.login, "#{gmurl(item.user)}", :class => 'nav' } | #{item.main_category.root.name} | #{print_tstamp(item.created_on, 'time')} | <span class="comments-count"><a title="Leer los comentarios de esta noticia" class="content" href="/noticias/show/#{item.id}#comments">#{item.cache_comments_count}</a></span></div>
          <div class="xdescription">#{auto_link_raw(smilelize(item.description))}</div>
        </div>
          END
        end
      end
      out2
    end
    out<< cache_out if cache_out

    out<< controller.send(
        :render_to_string,
        :partial => 'shared/pager2',
        :locals => {:collection => original_collection, :pos => 'bottom'}).force_encoding("utf-8")
    out<< '</div></div>'
  end

  def mfcontents_basic(title, object, find_args, opts={})
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
    out = "<div class=\"module mfcontents-list #{grid_cls} #{glast_cls} #{blast_cls}\"".force_encoding("utf-8")
    out << " id=\"#{options[:id]}\"" if options[:id]
    concat(out << "><div class=\"mtitle mcontent-title\"><span>#{title}</span></div><div class=\"mcontent\"><ul>")
    collection.each do |o|
      concat("<li #{'class="'<< options[:class] << '"' if options[:class]}>")
      yield o
      concat("</li>")
      ids<< o.unique_content.id
    end
    concat("</ul>")
    concat('<script type="text/javascript">contents = contents.concat('<< ids.join(',') <<');</script>')
    concat(options[:bottom]) if options[:bottom]
    concat("</div></div>")
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

    return '' if collection.size == 0 && !options[:show_even_if_empty]
    old_oddclass = @oddclass
    oddclass_reset
    grid_cls = options[:grid] ? "grid-#{options[:grid]}" : ''
    glast_cls = 'glast' if options[:glast]
    blast_cls = 'blast' if options[:blast]
    ids = []
    out = "<div class=\"module mfcontents-#{container_tag} #{grid_cls} #{blast_cls} #{glast_cls}\"".force_encoding("utf-8")
    out << " id=\"#{options[:id]}\"" if options[:id]
    concat(out << "><div class=\"mtitle\"><span>#{title}</span></div><div class=\"mcontent\"><#{container_tag}>")
    collection.each do |o|
      concat("<#{row_tag} class=\"content#{o.unique_content.id} new #{oddclass} #{options[:class] if options[:class]}\">")
      yield o
      concat("</#{row_tag}>")
      ids<< o.unique_content.id
    end
    concat("</#{container_tag}>")
    concat('<script type="text/javascript">contents = contents.concat('<< ids.join(',') <<');</script>')
    concat(options[:bottom]) if options[:bottom]
    concat("</div></div>")
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
    out.force_encoding("utf-8")
    collection.each do |item|
      ids<< item.unique_content.id
      out<< "<li class=\"new #{oddclass} content#{item.unique_content.id}\"><a title=\"#{tohtmlattribute(item.title)}\" href=\"#{gmurl(item)}\">"
      out<< content_category(item) if opts[:faction_favicon]
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

  def hue_selector(id, field_name, v)
    out = <<-END
    <div id="#{id}-hue-preview" style="width: 16px; height: 16px; float: left; border: 1px solid black;"></div>
    <input type="text" class="text" name="#{field_name}" value="#{v}" onclick="$('##{id}-hue-selector').removeClass('hidden');" />
<div id="#{id}-hue-selector" class="hidden"><img src="/images/hue_selector.png" onclick="cpMouseClick" /></div>
<script type="text/javascript">$('##{id}-hue-selector img').onclick = cpMouseClick;
    END

    if v then
      out<< <<-END
        $('##{id}-hue-preview').css('background', hsv2rgb(Math.round(#{v}), 100, 100));
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
          $('##{id}-hue-preview').css('background', '##{v.gsub('#','')}');
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
    <form method="post" action="#{form_destination}"><table><tr><th><input type="checkbox" onclick="Gm.Slnc.checkboxSwitchGroup(this);"></th>
  END
    columns.keys.each do |k|
      out<< "<th>#{k}</th>"
    end
    out<< '</tr>'
    collection.each do |item|
      out<< "<tr class=\"#{oddclass}\"><td><input type=\"checkbox\" name=\"#{input_name}[]\" onclick=\"Gm.Slnc.hilit_row(this, 'selrow');\" value=\"#{item.id}\" /></td>"
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
    <input type=\"submit\" class=\"confirm-click\" value=\"#{options[:submit_value]}\" /></form>"
  end

  def faction_activity_minicolumns(faction)
    # TODO esto no lo cachearan algunos browsers, usar .1.png
    "<img title=\"Karma generado durante el último mes en #{faction.code} (1 día una columna)\" class=\"minicolumns\" src=\"/storage/minicolumns/factions_activity/#{faction.id}.png?d=#{Time.now.strftime('%Y-%m-%d')}\" />"
  end

  def minicolumns(mode, data)
    mc_id = "minicols_{mode}#{data.join(',')}"
    f = "#{Rails.root}/public/storage/minicolumns/#{mc_id}.png"
    Cms.gen_minicolumns(mode, data, f) unless File.exists?(f)
    "<img src=\"/storage/minicolumns/#{mc_id}.png\" />"
  end

  def winner_cup(winner)
    "<img src=\"/images/blank.gif\" class=\"sprite1 competition-cup cup#{winner}\" />"
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
        controller._xad << asi.id.to_s
        out << "<div class=\"adslot\">#{asi.ad.ad_html(asi.id, asl.image_dimensions)}</div>"
      end
    end
    out
  end

  private
  def quicklinks_enabled_current_user_portal
    !user_is_authed || !ApplicationHelper::QUICKLINK_ENABLED_PORTALS.include?(
        controller.portal.class.name)
  end

  def current_portal_is_quicklink
    quicklinks = Personalization.quicklinks_for_user(@user)
    current_is_quicklink = false
    quicklinks.each do |quicklink|
      if quicklink[:code] == controller.portal.code
        current_is_quicklink = true
        break
      end
    end
    current_is_quicklink
  end

  def user_forums_enabled?
    user_is_authed && controller_name && 'foros' && !@forum.nil?
  end

  def user_forum_is_present
    buckets = Personalization.get_user_forums(@user)
    current_forum_is_present = false
      buckets.each do |saved_forum_id|
      if saved_forum_id == @forum.id
        current_forum_is_present = true
        break
      end
    end
    current_forum_is_present
  end

  def gm_icon(name, css_class=nil)
    "<span class=\"gm-icon #{css_class if css_class}\">#{GM_ICONS.fetch(name)}</span>"
  end

  # Layout helpers
  def content_names(contents)
    out = ["<div class=\"content-names\">"]
    contents.each do |content|
      out.append("<li><a href=\"#{Routing.gmurl(content)}\">#{content.resolve_hid}</a></li>")
    end
    out.append("</div>")
    out.join("\n")
  end
end
