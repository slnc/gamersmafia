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
  class DjJobWrapper
    def initialize(task)
      @task = task
    end
    
    def perform
      eval(@task)
    end
  end
  
  def self.running?(pid)
    # Check if process is in existence
    # The simplest way to do this is to send signal '0'
    # (which is a single system call) that doesn't actually
    # send a signal
    begin
      Process.kill(0, pid)
      return true
    rescue Errno::ESRCH
      return false
    rescue ::Exception   # for example on EPERM (process exists but does not belong to us)
      return true
    end
  end
  
  def self.kill_workers
    # we kill all currently active workers and spawn a new one
    Dir.glob("#{RAILS_ROOT}/tmp/pids/delayed_worker.*.pid").each do |fname|
      m = /\.([0-9]+)\.pid$/.match(fname)
      begin
        Process.kill('TERM', m[1].to_i)
        puts "killing delayed_job #{m[1]}"
        File.unlink("#{RAILS_ROOT}/tmp/pids/#{fname}")
      rescue
        puts "the bastard didn't want to die"
      end
    end
    
    Rake::Task["gm:spawn_worker"].invoke
  end
  
  def self.check_workers_pids
    # we remove pids not refering to anyone
    working_workers = 0
    Dir.glob("#{RAILS_ROOT}/tmp/pids/delayed_worker.*.pid").each do |fname|
      m = /\.([0-9]+)\.pid$/.match(fname)
      if running?(m[1].to_i)
        working_workers += 1
      else
        File.unlink("#{RAILS_ROOT}/tmp/pids/#{fname}")
      end
    end
    
    Rake::Task["gm:spawn_worker"].invoke if working_workers == 0
  end
  
  
  def self.job(task)
    # performs or schedules a lengthy job depending on the current configuration 
    if App.enable_bgjobs?
      Delayed::Job.enqueue DjJobWrapper.new(task)
      #Bj.submit('./script/runner /dev/stdin', 
      #          :rails_env => 'production',
      #          :stdin => task,
      #          :tag => task)
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
