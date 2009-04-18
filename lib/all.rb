load RAILS_ROOT + '/Rakefile'

class Time
  alias :strftime_nolocale :strftime
  
  def strftime(format) # PERF: too slow?
    format = format.dup
    format.gsub!(/%a/, Date::GM_ABBR_DAYNAMES[self.wday])
    format.gsub!(/%A/, Date::GM_DAYNAMES[self.wday])
    format.gsub!(/%b/, Date::GM_ABBR_MONTHNAMES[self.mon])
    format.gsub!(/%B/, Date::GM_MONTHNAMES[self.mon])
    self.strftime_nolocale(format)
  end
end


# if nil # ruby 1.8.7
class Date
  GM_MONTHNAMES = [nil, 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo',
      'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 
      'Diciembre']
  
  GM_ABBR_MONTHNAMES = [nil, 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dec']
  
  GM_DAYNAMES = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 
      'Viernes', 'Sábado']
  
  GM_ABBR_DAYNAMES = ['D', 'L', 'M', 'X', 'J', 'V', 'S']
end



class ActionController::Caching::Fragments::UnthreadedFileStore
  def write(name, value, options = nil) #:nodoc:
    ensure_cache_path(File.dirname(real_file_path(name)))
    f = File.open(real_file_path(name), "wb+")
    f.write(value)
    f.close
  rescue => e
    raise "Couldn't create cache directory: #{name} (#{e.message})"
  end
end

Infinity = 1.0/0