class ActionController::Base
  def remote_ip
    # necesario por el setup que usamos con mongrel y apache
    remote_ips = env.include?('HTTP_X_FORWARDED_FOR') ? env['HTTP_X_FORWARDED_FOR'] : env['REMOTE_ADDR']
    remote_ips.gsub!(',', ' ')
    remote_ips = remote_ips.split(' ').reject do |ip|
      ip =~ /^(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\./i || ip == 'unknown'
    end
    (remote_ips.first && remote_ips.first.strip != '') ? remote_ips.first.strip : '127.0.0.1'
  end
end