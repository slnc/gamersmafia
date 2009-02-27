require "#{File.dirname(__FILE__)}/../test_helper"

class AbstractPerformanceTest < ActionController::IntegrationTest
  
end

class HomeControllerPerformanceTest < AbstractPerformanceTest
  def test_index
    puts "index:"
    benchmark_time :get, '/'
    benchmark_memory :get, '/'
  end
  
  def benchmark_time(method, url)
    measured_times = []
    10.times { measured_times << Benchmark.realtime { send(method, url) } }
    puts "time: #{measured_times.mean.to_02f} ± #{Math.standard_deviation(measured_times).to_02f}\n"
  end
  
  def benchmark_memory(method, url)
    gc_statistics("memory: ") { send(method, url) }
  end
  
  def mean(values)
    values.sum / values.length
  end
  
  #def deviation(values)
  #  m = values.mean
  #  Math.sqrt(values.inject(0){|sum, a| sum + (a - m)**2} / values.length)
  #end
  
  
  def gc_statistics(description = "", options = {})
    #do nothing if we don't have patched Ruby GC
    yield and return unless GC.respond_to? :enable_stats
    
    GC.enable_stats || GC.clear_stats
    GC.disable if options[:disable_gc]
    
    yield
    
    stat_string = description + ": "
    stat_string += "allocated: #{GC.allocated_size/1024}K total in #{GC.num_allocations} allocations, "
    stat_string += "GC calls: #{GC.collections}, "
    stat_string += "GC time: #{GC.time / 1000} msec"
    
    GC.log stat_string
    puts stat_string
    GC.dump if options[:show_gc_dump]
    
    GC.enable if options[:disable_gc]
    GC.disable_stats
  end  
end
