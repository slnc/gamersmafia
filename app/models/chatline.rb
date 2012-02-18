class Chatline < ActiveRecord::Base
  belongs_to :user
  after_create :do_after_create
  
  def do_after_create
    return true # TODO temp disabled
    f_name = Kernel.rand(1000)
    
    while File.exists?("#{Rails.root}/tmp/ircmsgs/#{f_name}")
      f_name = Kernel.rand(1000)
    end
    
    if not File.exists?("#{Rails.root}/tmp/ircmsgs") then
      Dir.mkdir("#{Rails.root}/tmp/ircmsgs")
    end
    
    File.open("#{Rails.root}/tmp/ircmsgs/#{f_name}", 'w+') do |f|
      self.line.split("\n").each do |line|
        if self.user.login == 'MrAlariko'
          f.write("#{line}\n") if line.strip != ''
        else
          f.write("<#{self.user.login}> #{line}\n") if line.strip != ''
        end
      end
    end
  end
  
  def self.latest
    find(:all, :conditions => 'chatlines.created_on > now() - \'6 hours\'::interval', :order => 'chatlines.created_on desc', :limit => 100, :include => :user)
  end
end
