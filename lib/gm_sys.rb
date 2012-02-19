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
    Dir.glob("#{Rails.root}/tmp/pids/delayed_worker.*.pid").each do |fname|
      m = /\.([0-9]+)\.pid$/.match(fname)
      begin
        Process.kill('TERM', m[1].to_i)
        puts "killing delayed_job #{m[1]}" if App.debug
        File.unlink("#{Rails.root}/tmp/pids/#{fname}")
      rescue
        puts "the bastard didn't want to die" if App.debug
      end
    end

    Rake::Task["gm:spawn_worker"].invoke if App.enable_bgjobs?
  end

  def self.check_workers_pids
    # we remove pids not refering to anyone
    working_workers = 0
    Dir.glob("#{Rails.root}/tmp/pids/delayed_worker.*.pid").each do |fname|
      m = /\.([0-9]+)\.pid$/.match(fname)
      if running?(m[1].to_i)
        working_workers += 1
      else
        File.unlink(fname)
      end
    end

    Rake::Task["gm:spawn_worker"].invoke if App.enable_bgjobs? && working_workers == 0
  end


  def self.job(task)
    # performs or schedules a lengthy job depending on the current configuration
    if App.enable_bgjobs?
      Delayed::Job.enqueue DjJobWrapper.new(task)
    else
      eval(task)
    end
  end

  def self.command(task)
    # performs or schedules a direct bash command
    if App.enable_bgjobs?
      job("`#{task}`")
    else
      IO.popen(task) {|pipe| puts pipe.gets }
    end
  end
end