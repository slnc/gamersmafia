class Gm1932 < ActiveRecord::Migration
  def self.up
    Event.find(:all, :conditions => "website LIKE '/competiciones/show/%'").each do |e|
      puts e.name, e.website
      e.website = "http://arena.gamersmafia.com/competiciones/show/#{e.id}"
      e.save
    end
  end

  def self.down
  end
end
