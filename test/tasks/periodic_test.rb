require File.dirname(__FILE__) + '/../test_helper'
load RAILS_ROOT + '/Rakefile'
#load RAILS_ROOT + '/lib/tasks/periodic/daily.rake'

class PeriodicTest < Test::Unit::TestCase
  include Rake
  
  def test_periodic
    [:midnight, :hourly, :daily, :weekly, :weekly_report, :monthly].each do |task_name|
      assert get_task_names.include?("gm:#{task_name}")
      assert Rake::Task["gm:#{task_name}"].invoke
    end
  end
end
