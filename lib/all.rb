load RAILS_ROOT + '/Rakefile'

class Time
  alias :strftime_nolocale :strftime
  
  def strftime(format) # PERF: too slow?
    format = format.dup
    format.gsub!(/%a/, Date::ABBR_DAYNAMES[self.wday])
    format.gsub!(/%A/, Date::DAYNAMES[self.wday])
    format.gsub!(/%b/, Date::ABBR_MONTHNAMES[self.mon])
    format.gsub!(/%B/, Date::MONTHNAMES[self.mon])
    self.strftime_nolocale(format)
  end
end


# if nil # ruby 1.8.7
class Date
  MONTHNAMES = [nil, 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo',
      'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 
      'Diciembre']
  
  ABBR_MONTHNAMES = [nil, 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dec']
  
  DAYNAMES = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 
      'Viernes', 'Sábado']
  
  ABBR_DAYSNAMES = ['D', 'L', 'M', 'X', 'J', 'V', 'S']
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