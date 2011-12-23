require 'tidy'

module ActionViewMixings
  def get_visitor_id
    if cookies['__stma'] then # tenemos visitor_id, lo leemos ZimplY!
      # _udh + "." + _uu + "." + _ust + "." + _ust + "." + _ust + ".1";
      # 174166463.1739858544.1204186402.1206010305.1206018180.88
      # dom hash  visitor_id
      cka = cookies['__stma']
      #p cka.split('.')
      #raise 'fuck'
      cka.split('.')[1]
    else # creamos nuevo visitor_id
      new_visitor_id = (Kernel.rand * 2147483647).to_i
      # TODO tests!!
      params['_xnvi'] = new_visitor_id
    end
  end
  
  # executes the block if the current user belongs to the given treatment
  # opts
  #   :form : genera un campo hidden con la info del test actual
  def ab_test(test_name, treatment, opts={}, &block)
    raise "no tracking method given" if opts[:add_xab_to_links].nil? && opts[:form].nil? 
    abtest = AbTest.find_by_name(test_name)
    if abtest.nil?
      abtest = AbTest.new(:name => test_name, :treatments => treatment > 1 ? treatment : 1, :metrics => [:clickthrough])
      abtest.save
      Message.create(:user_id_from => User.find_by_login(App.ia_auto_abtests).id, :user_id_to => App.webmaster_user_id, :title => "AB Test '#{abtest.name}' creado automáticamente con #{abtest.treatments} tratamientos", :message => "Revisa que esté bien, ¿vale?") unless RAILS_ENV == 'test'
    end
    
    if abtest.completed_on  || controller.is_crawler?
      yield if treatment == 0 # en caso de que el test no exista mostramos el control y salimos
      return 
    end
    
    treatment_id, is_new = abtest.get_visitor_treatment_num(get_visitor_id)
    if is_new && controller.params['_xab_new_treated_visitors'][abtest.id.to_s]
      treatment_id = controller.params['_xab_new_treated_visitors'][abtest.id.to_s]
    else
      controller.params['_xab_new_treated_visitors'][abtest.id.to_s] = treatment_id
    end
    
    # return if controller.params['_xab'][abtest.id.to_s].to_s != '' && is_new # ya se ha llamado a otra opción antes
    controller.params['_xab'][abtest.id.to_s] = treatment_id.to_s
    if treatment_id == treatment
      if opts[:returnmode] == :out
        out = ''
        out<< "<div id=\"xab#{abtest.id}-#{treatment}\">" if opts[:add_xab_to_links]
        out<< "<input type=\"hidden\" name=\"_xca\" value=\"xab#{abtest.id}-#{treatment}\" />" if opts[:form]
        out<< block.call
        out<< "</div><script type=\"text/javascript\">slnc.marklinks('xab#{abtest.id}-#{treatment}', '_xca=xab#{abtest.id}-#{treatment}');</script>" if opts[:add_xab_to_links]
        out
      else
        concat("<div id=\"xab#{abtest.id}-#{treatment}\">") if opts[:add_xab_to_links]
        concat("<input type=\"hidden\" name=\"_xca\" value=\"xab#{abtest.id}-#{treatment}\" />") if opts[:form]
        yield
        concat("</div><script type=\"text/javascript\">slnc.marklinks('xab#{abtest.id}-#{treatment}', '_xca=xab#{abtest.id}-#{treatment}');</script>") if opts[:add_xab_to_links]        
      end
      # log it, why? podria ser una acción, un nuevo algoritmo, etc
      # bueno, entonces me preocuparé luego
    end
  end
  
  def print_tstamp(date, format='default', customformat=nil)
    formats = {'default' => '%d %b %Y, %H:%M',
               'time' => '%H:%M',
               'date' => '%d %b %Y',
               'custom' => '',
               'compact' => '%d/%m/%Y, %H:%M' }
    
    
    if format == 'unix'
      date.to_i
    elsif format == 'intelligent'
      d_now = Time.now.beginning_of_day
      if date >= d_now
        date.strftime_es('%H:%M')
      elsif date >= Time.local(d_now.year, 1, 1)
        date.strftime_es('%d %b')
      else
        date.strftime_es('%d/%m/%Y')
      end
    elsif format == 'custom'
      date.strftime_es(customformat)
    elsif date != nil 
      date.strftime_es(formats[format])
    else
        ''
    end
  end
  
  DEF_ALLOW_TAGS = ['a','img','p','br','i','b','u','ul','li', 'em', 'strong']
  
  def strip_tags_allowed(html, allow=DEF_ALLOW_TAGS)
    ActionView::Base.new.sanitize(html, :tags => allow, :attributes => %w(href title alt title name value width height src wmode type))
  end
  
  def oddclass
    @odd ||= 1
    @odd = 1 - @odd
    "alt#{@odd}"
  end
  
  def oddclass_reset
    @odd = 1
  end
  
  
  def ip_country_flag(ipaddr)
    ip_info = Geolocation.ip_info(ipaddr)
     (ip_info && ip_info[2].to_s != '') ? "<img class=\"icon\" title=\"#{ip_info[4]}\" alt=\"#{ip_info[4]}\" src=\"http://#{App.domain}/images/flags/#{ip_info[2].downcase}.gif\" />" : ''
  end
  
  
  # Para paginador
  unless const_defined?(:DEFAULT_OPTIONS)
    DEFAULT_OPTIONS = {
      :name => :page,
      :window_size => 2,
      :always_show_anchors => true,
      :link_to_current_page => false,
      :params => {}
    }
  end
  
  def pagination_links(paginator, options={}, html_options={})
    if params[:id]
      old_id = params[:id]
      params.delete(:id)
    else
      old_id = nil
    end
    
    options = DEFAULT_OPTIONS.merge(options)
    options.delete('') if options.has_key?('')
    
    params.delete('') if params.has_key?('')
    params2 = HashWithIndifferentAccess.new(params)
    params2[:params] = options[:params]
    
    window_pages = paginator.current.window(options[:window_size]).pages
    
    return if window_pages.length <= 1 unless
    options[:link_to_current_page]
    
    first, last = paginator.first, paginator.last
    
    if params2['controller'].match('/') then
      params2['controller'] = "/#{params2[:controller]}"
      params2['controller'].gsub!('//', '/')
    end
    
    
    validk = %w(action params controller page id category)
    validk = validk + (options[:preserve_keys].kind_of?(Array) ? options[:preserve_keys] : [options[:preserve_keys]]) if options[:preserve_keys] 
    params2.delete_if { |k,v| !validk.include?(k.to_s)}   
    returning html = '' do
      if options[:always_show_anchors] and not window_pages[0].first?
        html << link_to(paginator.first.number, params2.merge(:page => first.number), html_options) # "<a href=\"?page=#{first.number}\">#{paginator.first.number}</a>"
        html << ' ... ' if window_pages[0].number - first.number > 1
        html << ' '
      end
      
      window_pages.each do |page|
        if paginator.current == page && !options[:link_to_current_page]
          html << "<span class=\"currentpage\">#{page.number.to_s}</span>"
        else
          html << link_to(page.number, params2.merge(:page => page.number), html_options) #"<a href=\"?page=#{page.number}\">#{page.number}</a>"
        end
        html << ' '
      end
      
      if options[:always_show_anchors] && !window_pages.last.last?
        html << ' ... ' if last.number - window_pages[-1].number > 1
        html << link_to(paginator.last.number, params2.merge(:page => last.number), html_options) # "<a href=\"?page=#{first.number}\">#{paginator.first.number}</a>"
      end
      if old_id
        params[:id] = old_id
      end
    end
  end
  
  
  def clean_html(text, tags=['a','img','p','br','i','b','u','ul','li', 'em', 'strong', 'span', 'table', 'tr', 'td'])
    text = strip_tags_allowed(text, tags)
    Tidy.path = defined?(App.tidy_path) ? App.tidy_path : '/usr/lib/libtidy.so'
    xml = Tidy.open do |tidy|
      tidy.options.bare = 1
      tidy.options.doctype = 'omit'
      tidy.options.drop_empty_paras = 0
      tidy.options.drop_font_tags = 1
      tidy.options.drop_propietary_attributes = 1
      tidy.options.hide_comments = 1
      tidy.options.word_2000 = 1
      tidy.options.join_styles = 1
      tidy.options.logical_emphasis = 1
      tidy.options.quote_marks = 1
      tidy.options.show_body_only = 1
      tidy.options.char_encoding = 'utf8'
      tidy.clean(text)
    end
    xml
  end
  
  def tohtmlattribute(str)
    str.tr("<>'\"\n", '')
  end
  
  def flash_obj(h)
    # url=nil, width='100%', height='100%', name=nil
    if h[:name].nil? then
      h[:name] = File.dirname(h[:url]).gsub('.swf', '')
    end
    
    if h[:bgcolor]
      "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" width=\"#{h[:width]}\" height=\"#{h[:height]}\" id=\"#{h[:name]}\" align=\"middle\"><param name=\"movie\" value=\"#{h[:url]}\" /><param name=\"quality\" value=\"high\" /><param name=\"bgcolor\" value=\"#{h[:bgcolor]}\" /><embed src=\"#{h[:url]}\" quality=\"high\" bgcolor=\"#{h[:bg_color]}\" width=\"#{h[:width]}\" height=\"#{h[:height]}\" name=\"#{h[:name]}\" align=\"middle\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" /></object>"
    else
      "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" width=\"#{h[:width]}\" height=\"#{h[:height]}\" id=\"#{h[:name]}\" align=\"middle\"><param name=\"movie\" value=\"#{h[:url]}\" /><param name=\"quality\" value=\"high\" /><embed src=\"#{h[:url]}\" quality=\"high\" width=\"#{h[:width]}\" height=\"#{h[:height]}\" name=\"#{h[:name]}\" align=\"middle\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" /></object>"
    end
  end
  
  
  # sobrecargamos truncate para evitar el problema de las tíldes
  def truncate(text, length = 30, truncate_string = "...")
    if text.nil? then return end
    l = length - truncate_string.length
    $KCODE = 'u'
    chars = text.split(//)
    out = chars.length > length ? chars[0...l].join + truncate_string : text
    $KCODE = 'NONE'
    out
  end
  
  def format_interval_single_unit(time, unit)
    equivs = {'secs' => 1,
     'mins' => 60,
     'horas' => 3600,
     'días' => 86400,
     'semanas' => 86400 * 7,
     'meses' => 86400 * 31,
     'años' => 86400 * 365}
    "#{time.to_i / equivs[unit]} #{unit}"
  end
  
  def format_interval(time, resolution = 'mins', smallest = false)
    orig_time = time
    # la resolución es de más grande a más pequeño, si se especifica dias, se
    # pintan años, meses y días
    # smallest significa que se escriba la resolución con el menor número posible de letras
    time = time.to_i
    res = ""
    units = {}
    next_resolution = {'años' => 'meses', 
		       'meses' => 'semanas', 
		       'semanas' => 'días', 
		       'días' => 'horas', 
                       'horas' => 'mins', 
                       'mins' => 'secs', 
                       'secs' => nil}
    [ ["secs", 60], ["mins",   60], ["horas", 24], ["días", 7], ['semanas', 4], ["meses", 12], ["años",  1]].each do |name, unit|
      if name == resolution then
        res = '' # borramos lo calculado hasta ahora
      end
      
      if time % unit > 0 and name != 'secs' then
        units[name] = time % unit
        res = " #{time % unit} #{name}" + res
      end
      
      time /= unit
    end
    
    if smallest
      %w(años meses semanas días horas mins secs).each do |unit|
        if units[unit] == 0
          unit_ext = 'ningún'
        elsif units[unit] == 1
          unit_ext = (unit == 'meses') ? 'mes' : unit[0..-2]
        else
          unit_ext = unit
        end
        
        return "#{units[unit]} #{unit_ext}".strip if res[unit]
      end
      # si llegamos aquí es que la unidad pedida es muy grande para el tiempo que queda 
      # (por ej si han pedido horas y quedan minutos), mostramos la siguiente
      if resolution == 'secs'
        return ''
      else
        format_interval(orig_time, next_resolution[resolution], smallest)
      end
    else
      res.strip
    end
    
  end
end


class Time
  def slnc_print(format='default', customformat=nil)
    formats = {'default' => '%d %b %Y, %H:%M',
               'time' => '%H:%M',
               'date' => '%d %b %Y',
               'custom' => '',
               'compact' => '%d/%m/%Y, %H:%M' }
    
    
    if format == 'unix'
      self.to_i
    elsif format == 'full'
      "<span class=\"tstamp\">#{self.iso8601}</span>"
    elsif format == 'intelligent'
      d_now = Time.now.beginning_of_day
      if self >= d_now
        self.strftime_es('%H:%M')
      elsif self >= Time.local(d_now.year, 1, 1)
        self.strftime_es('%d %b')
      else
        self.strftime_es('%d/%m/%Y')
      end
    elsif format == 'custom'
      self.strftime_es(customformat)
    elsif self != nil 
      self.strftime_es(formats[format])
    else
        ''
    end
  end
end
