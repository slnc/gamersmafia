require 'test_helper'
load Rails.root + '/Rakefile'
#load Rails.root + '/lib/tasks/periodic/daily.rake'

class PeriodicTest < ActiveSupport::TestCase
  include Rake

  test "periodic" do
    [:midnight, :hourly, :daily, :weekly, :weekly_report, :monthly].each do |task_name|
      assert get_task_names.include?("gm:#{task_name}")
	  # NOTA: Si ya hemos invocado a la task anteriormente lo siguiente devolverá nil
      # pero si esa invocación ha fallado generará error que es lo que pretende
	  # recoger este test.
      Rake::Task["gm:#{task_name}"].invoke
    end
  end
end
