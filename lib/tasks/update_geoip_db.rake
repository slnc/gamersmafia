desc "Update the free GeoLiteCity database"
task :update_geoip_db => :environment do
  Geolocation.update_geoip_db
end
