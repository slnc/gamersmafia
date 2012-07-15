# -*- encoding : utf-8 -*-
# Delayed::Worker.destroy_failed_jobs = true
Delayed::Worker.sleep_delay = 5
# Delayed::Worker.max_attempts = 25
Delayed::Worker.max_run_time = 3.hours
Delayed::Worker.delay_jobs = App.enable_bgjobs?

if !App.enable_bgjobs? && !Rails.env.test?
  Rails.logger.warn("Background jobs disabled")
end
