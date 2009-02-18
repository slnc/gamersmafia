desc "Update the free GeoLiteCity database"
task :update_geoip_db do
  dst_dir = "#{RAILS_ROOT}/public/storage"
  File.unlink("#{App.tmp_dir}/GeoLiteCity.dat.gz") if File.exists?("#{App.tmp_dir}/GeoLiteCity.dat.gz")
  `cd #{App.tmp_dir} && wget http://www.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && gunzip GeoLiteCity.dat.gz && mv GeoLiteCity.dat #{dst_dir}`
end
