class BackfillScripts1 < ActiveRecord::Migration
  def up
    puts "Backfilling karma_rage.."
    (52 * 10).times do |year_week|
      puts "week: #{year_week}"
      UserEmblemObserver::Emblems.check_karma_rage(last_day=year_week.weeks.ago)
    end
  end

  def down
  end
end
