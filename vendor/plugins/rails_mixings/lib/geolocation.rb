require 'geoip'
load RAILS_ROOT + '/Rakefile'

module Geolocation
  if RAILS_ENV == 'test'
    DB_FILE = "#{RAILS_ROOT}/test/GeoLiteCity.dat.test"
  else
    DB_FILE = "#{RAILS_ROOT}/public/storage/GeoLiteCity.dat"
  end
  
  begin
    Rake::Task['update_geoip_db'].invoke unless File.exists?(DB_FILE)
    DISABLED=false
  rescue
    puts "Geolocation disabled"
    DISABLED=true
  end
  
  unless DISABLED
    @@g ||= GeoIP.new(DB_FILE)
    
    def self.country_code_by_addr(ipaddr)
      begin
        res = @@g.country(ipaddr)[2].to_s.downcase
      rescue
        @@g = GeoIP.new(DB_FILE)
        begin
          res = @@g.country(ipaddr)[2].to_s.downcase
        rescue
          res = '' # TODO avisar de que ipaddr es
        end
      end
      res == '--' ? '' : res
    end
    
    def self.ip_info(ipaddr)
      begin
        res = @@g.city(ipaddr)
      rescue
        @@g = GeoIP.new(DB_FILE)
        begin
          res = @@g.city(ipaddr)
        rescue
          res = '' # TODO avisar de que ipaddr es
        end
      end
      res == '--' ? '' : res
    end
    
    # Devuelve 'sa' si el usuario es de un país de sudamérica o 'es' en caso contrario
    SUDAMERICAN_COUNTRIES = %w(ar bo br cl co ec gy py pe sr uy ve gf)
    def self.resolve_ad_mode(ipaddr)
      SUDAMERICAN_COUNTRIES.include?(country_code_by_addr(ipaddr)) ? 'sa' : 'es'
    end
  end
end