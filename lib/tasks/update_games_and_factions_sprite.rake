require 'RMagick'

namespace :gm do
  desc "Update sprite of games and factions"
  task :update_games_and_factions_sprite => :environment do
    # items = Game.count + Platform.count + 1 # + 1 por icono de gm
    games = ([Game.new(:code => 'gm'), Game.new(:code => 'bazar'), Game.new(:code => 'arena')] + Game.find(:all, :order => 'lower(name) ASC') + Platform.find(:all, :order => 'lower(name) ASC') + BazarDistrict.find(:all, :order => 'lower(name) ASC'))
    items = games.size
    css_out = ''
    im = Magick::Image.new(items * 16, 16) { |i| i.background_color = 'none'}
    i = 0
     games.each do |t|
      begin
        bp = t.respond_to?(:icon) ? t.icon : "storage/games/#{t.code}.gif"
        im2 = Magick::Image.read("#{Rails.root}/public/#{bp}").first
        if im2.columns != 16 || im2.rows != 16
          puts "ERROR: #{t.code} is not a 16x16 img"
          next
        end
      rescue
        puts "cannot read image for #{t.code}"
      else
        im = im.store_pixels(i*16, 0, 16, 16, im2.get_pixels(0, 0, 16, 16))
      end
      css_out<< "img.gs-#{t.code} { background-position: -#{i*16}px 0; }\n"
      i += 1
    end
    File.open(Skin::FAVICONS_CSS_FILENAME, 'w') {|f| f.write(css_out) }

    im.quantize.write("#{Rails.root}/public/storage/gs.png")  unless `hostname`.strip == 'tachikoma' # para evitar que haya error por no tener píxeles
  end
end
