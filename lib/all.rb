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


class Date
  MONTHNAMES.replace([nil, 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo',
      'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 
      'Diciembre'])
  
  ABBR_MONTHNAMES.replace([nil, 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dec'])
  
  DAYNAMES.replace(['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 
      'Viernes', 'Sábado'])
  
  ABBR_DAYSNAMES = ['D', 'L', 'M', 'X', 'J', 'V', 'S']
end


class ActionController::Caching::Fragments::UnthreadedFileStore
  def write(name, value, options = nil) #:nodoc:
    puts "writing to #{name}"
    ensure_cache_path(File.dirname(real_file_path(name)))
    f = File.open(real_file_path(name), "wb+")
    f.write(value)
    f.close
  rescue => e
    raise "Couldn't create cache directory: #{name} (#{e.message})"
  end
end

Infinity = 1.0/0

module GmSys
  def self.job(task)
    # performs or schedules a lengthy job depending on the current configuration 
    if App.enable_bgjobs?
      Bj.submit('./script/runner /dev/stdin', 
                :rails_env => 'production',
                :stdin => task,
                :tag => task)
    else
      eval(task)
    end
  end
  
  def self.command(task)
    # performs or schedules a direct bash command 
    if App.enable_bgjobs?
      Bj.submit(task,
                :tag => task)
    else
      IO.popen(task) {|pipe| puts pipe.gets }
    end
  end
end