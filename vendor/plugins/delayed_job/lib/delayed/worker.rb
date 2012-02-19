module Delayed
  class Worker
    SLEEP = 5

    cattr_accessor :logger
    self.logger = if defined?(Merb::Logger)
                    Merb.logger
                  elsif defined?(RAILS_DEFAULT_LOGGER)
                    RAILS_DEFAULT_LOGGER
                  end

    def initialize(options={})
      @quiet = options[:quiet]
      Delayed::Job.min_priority = options[:min_priority] if options.has_key?(:min_priority)
      Delayed::Job.max_priority = options[:max_priority] if options.has_key?(:max_priority)
    end

    def start
      say "*** Starting job worker #{Delayed::Job.worker_name}"
      
      trap('TERM') { say 'Exiting...'; $exit = true }
      trap('INT')  { say 'Exiting...'; $exit = true }

      # save my pid so people can kill me
      pid_file = "#{RAILS_ROOT}/tmp/pids/delayed_worker.#{Process.pid}.pid"
      File.mkdir(File.dirname(pid_file)) unless File.exists?(File.dirname(pid_file))
      f = File.open(pid_file, 'w')
      f.write(Process.pid.to_s)
      f.close
      
      # grab current application version
      my_version = ActiveRecord::Base.db_query("SELECT svn_revision FROM global_vars")[0]['svn_revision'].to_i

      loop do
        # if operating svn_version has changed let's commit suicide
        cur_version = ActiveRecord::Base.db_query("SELECT svn_revision FROM global_vars")[0]['svn_revision'].to_i
        
        if cur_version != my_version
          say "my version (#{my_version}) differs from cur_version (#{cur_version}). Exiting.."
          break
        end
        
        result = nil

        realtime = Benchmark.realtime do
          result = Delayed::Job.work_off
        end

        count = result.sum

        break if $exit

        if count.zero?
          sleep(SLEEP)
        else
          say "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
        end

        break if $exit
      end

    ensure
      Delayed::Job.clear_locks!
    end

    def say(text)
      puts text unless @quiet
      logger.info text if logger
    end

  end
end
