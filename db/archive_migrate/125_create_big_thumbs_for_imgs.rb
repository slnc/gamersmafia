class CreateBigThumbsForImgs < ActiveRecord::Migration
  def self.up
    return
    max = 200
    i = 0
    Image.find(:all, :conditions => "state = #{Cms::PUBLISHED} AND file is not null AND id > 24387", :order => 'id asc').each do |im|
      # break if i >= max
      begin
      url = URI.encode("http://gamersmafia.com/cache/thumbnails/k/930x700/#{im.file}")
      r = Net::HTTP.get_response(URI.parse(url).host, URI.parse(url).path)
    rescue
      puts "Error al intentar llamar a img #{im.id} (#{url})"
    else
      puts "#{im.id} #{r.code}"
    end
      i += 1
      sleep 1 if i % 50
    end
  end

  def self.down
  end
end
