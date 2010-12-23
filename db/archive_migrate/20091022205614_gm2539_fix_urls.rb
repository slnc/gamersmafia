class Gm2539FixUrls < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.record_timestamps         = false
    counter = 1
    Content.find(:all, :conditions => 'created_on >= \'2009-03-01 00:00:00\'', :order => 'id').each do |c|
      prev = c.url
      c.url = nil
      Routing.gmurl(c)
      
      if c.url.gsub('.dev', '.com') != prev
        puts "#{c.id.to_s.ljust(7, ' ')}  #{c.created_on}   #{prev} >> #{c.url}"
        User.db_query("UPDATE contents set url = '#{c.url}' where id = #{c.id}")
      end
      counter += 1
    end
    puts counter
  end

  def self.down
  end
end
