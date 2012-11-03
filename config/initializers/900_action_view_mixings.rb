# -*- encoding : utf-8 -*-
#
module ActionViewMixings
  def remote_ip
    self.controller.remote_ip
  end

  def get_visitor_id
    if cookies['__stma'] then # tenemos visitor_id, lo leemos ZimplY!
      # _udh + "." + _uu + "." + _ust + "." + _ust + "." + _ust + ".1";
      # 174166463.1739858544.1204186402.1206010305.1206018180.88
      # dom hash  visitor_id
      cka = cookies['__stma']
      cka.split('.')[1]
    else # creamos nuevo visitor_id
      new_visitor_id = (Kernel.rand * 2147483647).to_i
      params['_xnvi'] = new_visitor_id
    end
  end

  # executes the block if the current user belongs to the given treatment
  # opts
  #   :form : genera un campo hidden con la info del test actual
  def show_ab_test(test_name, treatment, opts={}, &block)
    if opts[:add_xab_to_links].nil? && opts[:form].nil?
      raise "No tracking method given for ab_test #{test_name}"
    end

    ab_test = AbTest.find_by_name(test_name)
    if Rails.env == "test"
      return if ab_test.nil?
    else
      ab_test = create_ab_test(test_name, treatment) if ab_test.nil?
    end

    if ab_test.completed_on || controller.is_crawler?
      # We show control version if test is completed or user is a crawler.
      yield if treatment == 0
      return
    end

    treatment_id, is_new = ab_test.get_visitor_treatment_num(get_visitor_id)
    if is_new && controller.params['_xab_new_treated_visitors'][ab_test.id.to_s]
      treatment_id = controller.params['_xab_new_treated_visitors'][ab_test.id.to_s]
    else
      controller.params['_xab_new_treated_visitors'][ab_test.id.to_s] = treatment_id
    end

    controller.params['_xab'][ab_test.id.to_s] = treatment_id.to_s
    if treatment_id == treatment
      if opts[:returnmode] == :out
        render_ab_test_to_string(ab_test, treatment, opts, &block)
      else
        render_ab_test_to_erb(ab_test, treatment, opts, &block)
      end
    end
  end

  def create_ab_test(test_name, treatment)
    AbTest.create({
      :name => test_name,
      :treatments => treatment > 1 ? treatment : 1,
      :metrics => [:clickthrough],
    })
  end

  def get_ab_test_strings(ab_test, treatment, opts)
    lines_before = []
    if opts[:add_xab_to_links]
      lines_before << "<div id=\"xab#{ab_test.id}-#{treatment}\">"
    end
    if opts[:form]
      lines_before << "<input type=\"hidden\" name=\"_xca\" value=\"xab#{ab_test.id}-#{treatment}\" />"
    end

    lines_after = []
    if opts[:add_xab_to_links]
      lines_after << <<-END
</div>
<script type="text/javascript">
Gm.Slnc.marklinks(
    'xab#{ab_test.id}-#{treatment}', '_xca=xab#{ab_test.id}-#{treatment}');
</script>
      END
    end
    [lines_before, lines_after]
  end

  def render_ab_test_to_erb(ab_test, treatment, opts, &block)
    (lines_before, lines_after) = get_ab_test_strings(ab_test, treatment, opts)
    lines_before.each { |line| concat(line) }
    yield
    lines_after.each { |line| concat(line) }
  end

  def render_ab_test_to_string(ab_test, treatment, opts, &block)
    (lines_before, lines_after) = get_ab_test_strings(ab_test, treatment, opts)
    out = lines_before
    out << block.call
    out.extend(lines_after)
    out.join
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
    ActionView::Base.new.sanitize(
        html,
        :tags => allow,
        :attributes =>
            %w(href title alt title name value width height src wmode type))
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
    chars = text.split(//)
    out = chars.length > length ? chars[0...l].join + truncate_string : text
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

ActionView::Base.send :include, ActionViewMixings
